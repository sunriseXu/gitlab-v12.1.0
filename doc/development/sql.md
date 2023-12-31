# SQL Query Guidelines

This document describes various guidelines to follow when writing SQL queries,
either using ActiveRecord/Arel or raw SQL queries.

## Using LIKE Statements

The most common way to search for data is using the `LIKE` statement. For
example, to get all issues with a title starting with "WIP:" you'd write the
following query:

```sql
SELECT *
FROM issues
WHERE title LIKE 'WIP:%';
```

On PostgreSQL the `LIKE` statement is case-sensitive. On MySQL this depends on
the case-sensitivity of the collation, which is usually case-insensitive. To
perform a case-insensitive `LIKE` on PostgreSQL you have to use `ILIKE` instead.
This statement in turn isn't supported on MySQL.

To work around this problem you should write `LIKE` queries using Arel instead
of raw SQL fragments as Arel automatically uses `ILIKE` on PostgreSQL and `LIKE`
on MySQL. This means that instead of this:

```ruby
Issue.where('title LIKE ?', 'WIP:%')
```

You'd write this instead:

```ruby
Issue.where(Issue.arel_table[:title].matches('WIP:%'))
```

Here `matches` generates the correct `LIKE` / `ILIKE` statement depending on the
database being used.

If you need to chain multiple `OR` conditions you can also do this using Arel:

```ruby
table = Issue.arel_table

Issue.where(table[:title].matches('WIP:%').or(table[:foo].matches('WIP:%')))
```

For PostgreSQL this produces:

```sql
SELECT *
FROM issues
WHERE (title ILIKE 'WIP:%' OR foo ILIKE 'WIP:%')
```

In turn for MySQL this produces:

```sql
SELECT *
FROM issues
WHERE (title LIKE 'WIP:%' OR foo LIKE 'WIP:%')
```

## LIKE & Indexes

Neither PostgreSQL nor MySQL use any indexes when using `LIKE` / `ILIKE` with a
wildcard at the start. For example, this will not use any indexes:

```sql
SELECT *
FROM issues
WHERE title ILIKE '%WIP:%';
```

Because the value for `ILIKE` starts with a wildcard the database is not able to
use an index as it doesn't know where to start scanning the indexes.

MySQL provides no known solution to this problem. Luckily PostgreSQL _does_
provide a solution: trigram GIN indexes. These indexes can be created as
follows:

```sql
CREATE INDEX [CONCURRENTLY] index_name_here
ON table_name
USING GIN(column_name gin_trgm_ops);
```

The key here is the `GIN(column_name gin_trgm_ops)` part. This creates a [GIN
index][gin-index] with the operator class set to `gin_trgm_ops`. These indexes
_can_ be used by `ILIKE` / `LIKE` and can lead to greatly improved performance.
One downside of these indexes is that they can easily get quite large (depending
on the amount of data indexed).

To keep naming of these indexes consistent please use the following naming
pattern:

```
index_TABLE_on_COLUMN_trigram
```

For example, a GIN/trigram index for `issues.title` would be called
`index_issues_on_title_trigram`.

Due to these indexes taking quite some time to be built they should be built
concurrently. This can be done by using `CREATE INDEX CONCURRENTLY` instead of
just `CREATE INDEX`. Concurrent indexes can _not_ be created inside a
transaction. Transactions for migrations can be disabled using the following
pattern:

```ruby
class MigrationName < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
end
```

For example:

```ruby
class AddUsersLowerUsernameEmailIndexes < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    execute 'CREATE INDEX CONCURRENTLY index_on_users_lower_username ON users (LOWER(username));'
    execute 'CREATE INDEX CONCURRENTLY index_on_users_lower_email ON users (LOWER(email));'
  end

  def down
    return unless Gitlab::Database.postgresql?

    remove_index :users, :index_on_users_lower_username
    remove_index :users, :index_on_users_lower_email
  end
end
```

## Plucking IDs

This can't be stressed enough: **never** use ActiveRecord's `pluck` to pluck a
set of values into memory only to use them as an argument for another query. For
example, this will make the database **very** sad:

```ruby
projects = Project.all.pluck(:id)

MergeRequest.where(source_project_id: projects)
```

Instead you can just use sub-queries which perform far better:

```ruby
MergeRequest.where(source_project_id: Project.all.select(:id))
```

The _only_ time you should use `pluck` is when you actually need to operate on
the values in Ruby itself (e.g. write them to a file). In almost all other cases
you should ask yourself "Can I not just use a sub-query?".

In line with our `CodeReuse/ActiveRecord` cop, you should only use forms like
`pluck(:id)` or `pluck(:user_id)` within model code. In the former case, you can
use the `ApplicationRecord`-provided `.pluck_primary_key` helper method instead.
In the latter, you should add a small helper method to the relevant model.

## Inherit from ApplicationRecord

Most models in the GitLab codebase should inherit from `ApplicationRecord`,
rather than from `ActiveRecord::Base`. This allows helper methods to be easily
added.

An exception to this rule exists for models created in database migrations. As
these should be isolated from application code, they should continue to subclass
from `ActiveRecord::Base`.

## Use UNIONs

UNIONs aren't very commonly used in most Rails applications but they're very
powerful and useful. In most applications queries tend to use a lot of JOINs to
get related data or data based on certain criteria, but JOIN performance can
quickly deteriorate as the data involved grows.

For example, if you want to get a list of projects where the name contains a
value _or_ the name of the namespace contains a value most people would write
the following query:

```sql
SELECT *
FROM projects
JOIN namespaces ON namespaces.id = projects.namespace_id
WHERE projects.name ILIKE '%gitlab%'
OR namespaces.name ILIKE '%gitlab%';
```

Using a large database this query can easily take around 800 milliseconds to
run. Using a UNION we'd write the following instead:

```sql
SELECT projects.*
FROM projects
WHERE projects.name ILIKE '%gitlab%'

UNION

SELECT projects.*
FROM projects
JOIN namespaces ON namespaces.id = projects.namespace_id
WHERE namespaces.name ILIKE '%gitlab%';
```

This query in turn only takes around 15 milliseconds to complete while returning
the exact same records.

This doesn't mean you should start using UNIONs everywhere, but it's something
to keep in mind when using lots of JOINs in a query and filtering out records
based on the joined data.

GitLab comes with a `Gitlab::SQL::Union` class that can be used to build a UNION
of multiple `ActiveRecord::Relation` objects. You can use this class as
follows:

```ruby
union = Gitlab::SQL::Union.new([projects, more_projects, ...])

Project.from("(#{union.to_sql}) projects")
```

## Ordering by Creation Date

When ordering records based on the time they were created you can simply order
by the `id` column instead of ordering by `created_at`. Because IDs are always
unique and incremented in the order that rows are created this will produce the
exact same results. This also means there's no need to add an index on
`created_at` to ensure consistent performance as `id` is already indexed by
default.

## Use WHERE EXISTS instead of WHERE IN

While `WHERE IN` and `WHERE EXISTS` can be used to produce the same data it is
recommended to use `WHERE EXISTS` whenever possible. While in many cases
PostgreSQL can optimise `WHERE IN` quite well there are also many cases where
`WHERE EXISTS` will perform (much) better.

In Rails you have to use this by creating SQL fragments:

```ruby
Project.where('EXISTS (?)', User.select(1).where('projects.creator_id = users.id AND users.foo = X'))
```

This would then produce a query along the lines of the following:

```sql
SELECT *
FROM projects
WHERE EXISTS (
    SELECT 1
    FROM users
    WHERE projects.creator_id = users.id
    AND users.foo = X
)
```

[gin-index]: http://www.postgresql.org/docs/current/static/gin.html

## `.find_or_create_by` is not atomic

The inherent pattern with methods like `.find_or_create_by` and
`.first_or_create` and others is that they are not atomic. This means,
it first runs a `SELECT`, and if there are no results an `INSERT` is
performed. With concurrent processes in mind, there is a race condition
which may lead to trying to insert two similar records. This may not be
desired, or may cause one of the queries to fail due to a constraint
violation, for example.

Using transactions does not solve this problem.

To solve this we've added the `ApplicationRecord.safe_find_or_create_by`.

This method can be used just as you would the normal
`find_or_create_by` but it wraps the call in a *new* transaction and
retries if it were to fail because of an
`ActiveRecord::RecordNotUnique` error.

To be able to use this method, make sure the model you want to use
this on inherits from `ApplicationRecord`.

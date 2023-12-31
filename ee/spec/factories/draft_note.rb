# frozen_string_literal: true
FactoryBot.define do
  factory :draft_note do
    note { generate(:title) }
    association :author, factory: :user
    association :merge_request, factory: :merge_request

    factory :draft_note_on_text_diff do
      transient do
        line_number 14
        diff_refs { merge_request.try(:diff_refs) }
      end

      position do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: nil,
          new_line: line_number,
          diff_refs: diff_refs
        )
      end
    end

    factory :draft_note_on_discussion, traits: [:on_discussion]

    trait :on_discussion do
      discussion_id { create(:discussion_note_on_merge_request, noteable: merge_request, project: project).discussion_id }
    end
  end
end

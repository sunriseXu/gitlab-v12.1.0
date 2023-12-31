# frozen_string_literal: true

module Commits
  class CreateService < ::BaseService
    ValidationError = Class.new(StandardError)
    ChangeError = Class.new(StandardError)

    def initialize(*args)
      super

      @start_project = params[:start_project] || @project
      @start_branch = params[:start_branch]
      @branch_name = params[:branch_name]
      @force = params[:force] || false
    end

    def execute
      validate!

      new_commit = create_commit!

      success(result: new_commit)
    rescue ValidationError,
           ChangeError,
           Gitlab::Git::Index::IndexError,
           Gitlab::Git::CommitError,
           Gitlab::Git::PreReceiveError,
           Gitlab::Git::CommandError => ex
      error(ex.message)
    end

    private

    def create_commit!
      raise NotImplementedError
    end

    def raise_error(message)
      raise ValidationError, message
    end

    def different_branch?
      @start_branch != @branch_name || @start_project != @project
    end

    def force?
      !!@force
    end

    def validate!
      validate_permissions!
      validate_on_branch!
      validate_branch_existence!

      validate_new_branch_name! if different_branch?
    end

    def validate_permissions!
      allowed = ::Gitlab::UserAccess.new(current_user, project: project).can_push_to_branch?(@branch_name)

      unless allowed
        raise_error("You are not allowed to push into this branch")
      end
    end

    def validate_on_branch!
      if !@start_project.empty_repo? && !@start_project.repository.branch_exists?(@start_branch)
        raise_error('You can only create or edit files when you are on a branch')
      end
    end

    def validate_branch_existence!
      if !project.empty_repo? && different_branch? && repository.branch_exists?(@branch_name) && !force?
        raise_error("A branch called '#{@branch_name}' already exists. Switch to that branch in order to make changes")
      end
    end

    def validate_new_branch_name!
      result = ValidateNewBranchService.new(project, current_user).execute(@branch_name, force: force?)

      if result[:status] == :error
        raise_error("Something went wrong when we tried to create '#{@branch_name}' for you: #{result[:message]}")
      end
    end
  end
end

Commits::CreateService.prepend(EE::Commits::CreateService)

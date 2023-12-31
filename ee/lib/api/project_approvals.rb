# frozen_string_literal: true

module API
  class ProjectApprovals < ::Grape::API
    before { authenticate! }
    before { authorize! :update_approvers, user_project }

    ARRAY_COERCION_LAMBDA = ->(val) { val.empty? ? [] : Array.wrap(val) }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approvals' do
        desc 'Get all project approvers and related configuration' do
          detail 'This feature was introduced in 10.6'
          success EE::API::Entities::ApprovalSettings
        end
        get '/' do
          present user_project.present(current_user: current_user), with: EE::API::Entities::ApprovalSettings
        end

        desc 'Change approval-related configuration' do
          detail 'This feature was introduced in 10.6'
          success EE::API::Entities::ApprovalSettings
        end
        params do
          optional :approvals_before_merge, type: Integer, desc: 'The amount of approvals required before an MR can be merged'
          optional :reset_approvals_on_push, type: Boolean, desc: 'Should the approval count be reset on a new push'
          optional :disable_overriding_approvers_per_merge_request, type: Boolean, desc: 'Should MRs be able to override approvers and approval count'
          optional :merge_requests_author_approval, type: Boolean, desc: 'Should authors be able to self approve merge requests'
          at_least_one_of :approvals_before_merge, :reset_approvals_on_push, :disable_overriding_approvers_per_merge_request, :merge_requests_author_approval
        end
        post '/' do
          project_params = declared(params, include_missing: false, include_parent_namespaces: false)

          result = ::Projects::UpdateService.new(user_project, current_user, project_params).execute

          if result[:status] == :success
            present user_project.present(current_user: current_user), with: EE::API::Entities::ApprovalSettings
          else
            render_validation_error!(user_project)
          end
        end
      end

      desc 'Update approvers and approver groups' do
        detail 'This feature was introduced in 10.6'
        success EE::API::Entities::ApprovalSettings
      end
      params do
        requires :approver_ids, type: Array[String], coerce_with: ARRAY_COERCION_LAMBDA, desc: 'Array of User IDs to set as approvers.'
        requires :approver_group_ids, type: Array[String], coerce_with: ARRAY_COERCION_LAMBDA, desc: 'Array of Group IDs to set as approvers.'
      end
      put ':id/approvers' do
        result = ::Projects::UpdateService.new(user_project, current_user, declared(params, include_parent_namespaces: false).merge(remove_old_approvers: true)).execute

        if result[:status] == :success
          present user_project.present(current_user: current_user), with: EE::API::Entities::ApprovalSettings
        else
          render_validation_error!(user_project)
        end
      end
    end
  end
end

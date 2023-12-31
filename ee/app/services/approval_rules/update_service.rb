# frozen_string_literal: true

module ApprovalRules
  class UpdateService < ::ApprovalRules::BaseService
    attr_reader :rule, :keep_existing_hidden_groups

    def initialize(approval_rule, user, params)
      @rule = approval_rule
      @keep_existing_hidden_groups = !Gitlab::Utils.to_boolean(params.delete(:remove_hidden_groups))

      super(@rule.project, user, params)
    end

    def filter_eligible_groups!
      super

      # Append hidden groups unless removal is explicitly stated,
      # as hidden group ids are never passed to/back from clients for security reasons.
      if params[:groups] && keep_existing_hidden_groups
        params[:groups] += GroupFinder.new(rule, current_user).hidden_groups
      end
    end
  end
end

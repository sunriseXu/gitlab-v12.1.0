# frozen_string_literal: true

module EE
  module Issues
    module MoveService
      extend ::Gitlab::Utils::Override

      override :update_old_entity
      def update_old_entity
        rewrite_epic_issue
        super
      end

      private

      def rewrite_epic_issue
        return unless epic_issue = original_entity.epic_issue
        return unless can?(current_user, :update_epic, epic_issue.epic.group)

        epic_issue.update(issue_id: new_entity.id)
        original_entity.reset
      end
    end
  end
end

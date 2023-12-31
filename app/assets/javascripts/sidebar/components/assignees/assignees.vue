<script>
import { __, sprintf } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'Assignees',
  directives: {
    tooltip,
  },
  props: {
    rootPath: {
      type: String,
      required: true,
    },
    users: {
      type: Array,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
    issuableType: {
      type: String,
      require: true,
      default: 'issue',
    },
  },
  data() {
    return {
      defaultRenderCount: 5,
      defaultMaxCounter: 99,
      showLess: true,
    };
  },
  computed: {
    firstUser() {
      return this.users[0];
    },
    hasMoreThanTwoAssignees() {
      return this.users.length > 2;
    },
    hasMoreThanOneAssignee() {
      return this.users.length > 1;
    },
    hasAssignees() {
      return this.users.length > 0;
    },
    hasNoUsers() {
      return !this.users.length;
    },
    hasOneUser() {
      return this.users.length === 1;
    },
    renderShowMoreSection() {
      return this.users.length > this.defaultRenderCount;
    },
    numberOfHiddenAssignees() {
      return this.users.length - this.defaultRenderCount;
    },
    isHiddenAssignees() {
      return this.numberOfHiddenAssignees > 0;
    },
    hiddenAssigneesLabel() {
      const { numberOfHiddenAssignees } = this;
      return sprintf(__('+ %{numberOfHiddenAssignees} more'), { numberOfHiddenAssignees });
    },
    collapsedTooltipTitle() {
      const maxRender = Math.min(this.defaultRenderCount, this.users.length);
      const renderUsers = this.users.slice(0, maxRender);
      const names = renderUsers.map(u => u.name);

      if (this.users.length > maxRender) {
        names.push(`+ ${this.users.length - maxRender} more`);
      }

      if (!this.users.length) {
        const emptyTooltipLabel = __('Assignee(s)');
        names.push(emptyTooltipLabel);
      }

      return names.join(', ');
    },
    sidebarAvatarCounter() {
      let counter = `+${this.users.length - 1}`;

      if (this.users.length > this.defaultMaxCounter) {
        counter = `${this.defaultMaxCounter}+`;
      }

      return counter;
    },
    mergeNotAllowedTooltipMessage() {
      const assigneesCount = this.users.length;

      if (this.issuableType !== 'merge_request' || assigneesCount === 0) {
        return null;
      }

      const cannotMergeCount = this.users.filter(u => u.can_merge === false).length;
      const canMergeCount = assigneesCount - cannotMergeCount;

      if (canMergeCount === assigneesCount) {
        // Everyone can merge
        return null;
      } else if (cannotMergeCount === assigneesCount && assigneesCount > 1) {
        return __('No one can merge');
      } else if (assigneesCount === 1) {
        return __('Cannot merge');
      }

      return sprintf(__('%{canMergeCount}/%{assigneesCount} can merge'), {
        canMergeCount,
        assigneesCount,
      });
    },
  },
  methods: {
    assignSelf() {
      this.$emit('assign-self');
    },
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    renderAssignee(index) {
      return !this.showLess || (index < this.defaultRenderCount && this.showLess);
    },
    avatarUrl(user) {
      return user.avatar || user.avatar_url || gon.default_avatar_url;
    },
    assigneeUrl(user) {
      return `${this.rootPath}${user.username}`;
    },
    assigneeAlt(user) {
      return sprintf(__("%{userName}'s avatar"), { userName: user.name });
    },
    assigneeUsername(user) {
      return `@${user.username}`;
    },
    shouldRenderCollapsedAssignee(index) {
      const firstTwo = this.users.length <= 2 && index <= 2;

      return index === 0 || firstTwo;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-tooltip
      :class="{ 'multiple-users': hasMoreThanOneAssignee }"
      :title="collapsedTooltipTitle"
      class="sidebar-collapsed-icon sidebar-collapsed-user"
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
    >
      <i v-if="hasNoUsers" :aria-label="__('None')" class="fa fa-user"> </i>
      <button
        v-for="(user, index) in users"
        v-if="shouldRenderCollapsedAssignee(index)"
        :key="user.id"
        type="button"
        class="btn-link"
      >
        <img
          :alt="assigneeAlt(user)"
          :src="avatarUrl(user)"
          width="24"
          class="avatar avatar-inline s24"
        />
        <span class="author"> {{ user.name }} </span>
      </button>
      <button v-if="hasMoreThanTwoAssignees" class="btn-link" type="button">
        <span class="avatar-counter sidebar-avatar-counter"> {{ sidebarAvatarCounter }} </span>
      </button>
    </div>
    <div class="value hide-collapsed">
      <span
        v-if="mergeNotAllowedTooltipMessage"
        v-tooltip
        :title="mergeNotAllowedTooltipMessage"
        data-placement="left"
        class="float-right cannot-be-merged"
      >
        <i aria-hidden="true" data-hidden="true" class="fa fa-exclamation-triangle"></i>
      </span>
      <template v-if="hasNoUsers">
        <span class="assign-yourself no-value qa-assign-yourself">
          {{ __('None') }}
          <template v-if="editable">
            -
            <button type="button" class="btn-link" @click="assignSelf">
              {{ __('assign yourself') }}
            </button>
          </template>
        </span>
      </template>
      <template v-else-if="hasOneUser">
        <a :href="assigneeUrl(firstUser)" class="author-link bold">
          <img
            :alt="assigneeAlt(firstUser)"
            :src="avatarUrl(firstUser)"
            width="32"
            class="avatar avatar-inline s32"
          />
          <span class="author"> {{ firstUser.name }} </span>
          <span class="username"> {{ assigneeUsername(firstUser) }} </span>
        </a>
      </template>
      <template v-else>
        <div class="user-list">
          <div
            v-for="(user, index) in users"
            v-if="renderAssignee(index)"
            :key="user.id"
            class="user-item"
          >
            <a
              :href="assigneeUrl(user)"
              :data-title="user.name"
              class="user-link has-tooltip"
              data-container="body"
              data-placement="bottom"
            >
              <img
                :alt="assigneeAlt(user)"
                :src="avatarUrl(user)"
                width="32"
                class="avatar avatar-inline s32"
              />
            </a>
          </div>
        </div>
        <div v-if="renderShowMoreSection" class="user-list-more">
          <button type="button" class="btn-link" @click="toggleShowLess">
            <template v-if="showLess">
              {{ hiddenAssigneesLabel }}
            </template>
            <template v-else>{{ __('- show less') }}</template>
          </button>
        </div>
      </template>
    </div>
  </div>
</template>

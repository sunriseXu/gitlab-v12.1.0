<script>
import ListLabel from '~/boards/models/label';
import BoardLabelsSelect from '~/vue_shared/components/sidebar/labels_select/base.vue';
import BoardMilestoneSelect from './milestone_select.vue';
import BoardWeightSelect from './weight_select.vue';
import AssigneeSelect from './assignee_select.vue';

export default {
  components: {
    AssigneeSelect,
    BoardLabelsSelect,
    BoardMilestoneSelect,
    BoardWeightSelect,
  },

  props: {
    collapseScope: {
      type: Boolean,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    board: {
      type: Object,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    scopedLabelsDocumentationLink: {
      type: String,
      required: false,
      default: '#',
    },
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: Number,
      required: false,
      default: 0,
    },
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    weights: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  data() {
    return {
      expanded: false,
    };
  },

  computed: {
    expandButtonText() {
      return this.expanded ? 'Collapse' : 'Expand';
    },
  },

  methods: {
    handleLabelClick(label) {
      if (label.isAny) {
        this.board.labels = [];
      } else if (!this.board.labels.find(l => l.id === label.id)) {
        this.board.labels.push(
          new ListLabel({
            id: label.id,
            title: label.title,
            color: label.color[0],
            textColor: label.text_color,
          }),
        );
      } else {
        let { labels } = this.board;
        labels = labels.filter(selected => selected.id !== label.id);
        this.board.labels = labels;
      }
    },
  },
};
</script>

<template>
  <div>
    <div v-if="canAdminBoard" class="media append-bottom-10">
      <label class="form-section-title label-bold media-body"> Board scope </label>
      <button v-if="collapseScope" type="button" class="btn" @click="expanded = !expanded">
        {{ expandButtonText }}
      </button>
    </div>
    <p class="text-secondary append-bottom-10">
      Board scope affects which issues are displayed for anyone who visits this board
    </p>
    <div v-if="!collapseScope || expanded">
      <board-milestone-select
        :board="board"
        :milestone-path="milestonePath"
        :can-edit="canAdminBoard"
      />

      <board-labels-select
        :context="board"
        :labels-path="labelsPath"
        :can-edit="canAdminBoard"
        :scoped-labels-documentation-link="scopedLabelsDocumentationLink"
        :enable-scoped-labels="enableScopedLabels"
        ability-name="issue"
        @onLabelClick="handleLabelClick"
      >
        {{ __('Any Label') }}
      </board-labels-select>

      <assignee-select
        :board="board"
        :selected="board.assignee"
        :can-edit="canAdminBoard"
        :project-id="projectId"
        :group-id="groupId"
        any-user-text="Any assignee"
        field-name="assignee_id"
        label="Assignee"
        placeholder-text="Select assignee"
        wrapper-class="assignee"
      />

      <board-weight-select
        v-model="board.weight"
        :board="board"
        :weights="weights"
        :can-edit="canAdminBoard"
      />
    </div>
  </div>
</template>

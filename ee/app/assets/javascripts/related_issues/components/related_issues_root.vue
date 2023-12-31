<script>
/*
`rawReferences` are separated by spaces.
Given `abc 123 zxc`, `rawReferences = ['abc', '123', 'zxc']`

Consider you are typing `abc 123 zxc` in the input and your caret position is
at position 4 right before the `123` `rawReference`. Then you type `#` and
it becomes a valid reference, `#123`, but we don't want to jump it straight into
`pendingReferences` because you could still want to type. Say you typed `999`
and now we have `#999123`. Only when you move your caret away from that `rawReference`
do we actually put it in the `pendingReferences`.

Your caret can stop touching a `rawReference` can happen in a variety of ways:

 - As you type, we only tokenize after you type a space or move with the arrow keys
 - On blur, we consider your caret not touching anything

---

 - When you click the "Add related issues"(in the `AddIssuableForm`),
   we submit the `pendingReferences` to the server and they come back as actual `relatedIssues`
 - When you click the "Cancel"(in the `AddIssuableForm`), we clear out `pendingReferences`
   and hide the `AddIssuableForm` area.

*/
import _ from 'underscore';
import Flash from '~/flash';
import RelatedIssuesBlock from './related_issues_block.vue';
import RelatedIssuesStore from '../stores/related_issues_store';
import RelatedIssuesService from '../services/related_issues_service';
import {
  relatedIssuesRemoveErrorMap,
  pathIndeterminateErrorMap,
  addRelatedIssueErrorMap,
  issuableTypesMap,
} from '../constants';

export default {
  name: 'RelatedIssuesRoot',
  components: {
    relatedIssuesBlock: RelatedIssuesBlock,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    canAdmin: {
      type: Boolean,
      required: false,
      default: false,
    },
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: 'Related issues',
    },
    issuableType: {
      type: String,
      required: false,
      default: issuableTypesMap.ISSUE,
    },
    allowAutoComplete: {
      type: Boolean,
      required: false,
      default: true,
    },
    pathIdSeparator: {
      type: String,
      required: false,
      default: '#',
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    this.store = new RelatedIssuesStore();

    return {
      state: this.store.state,
      isFetching: false,
      isSubmitting: false,
      isFormVisible: false,
      inputValue: '',
    };
  },
  computed: {
    autoCompleteSources() {
      if (!this.allowAutoComplete) return {};
      return gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;
    },
  },
  created() {
    this.service = new RelatedIssuesService(this.endpoint);
    this.fetchRelatedIssues();
  },
  methods: {
    onRelatedIssueRemoveRequest(idToRemove) {
      const issueToRemove = _.find(this.state.relatedIssues, issue => issue.id === idToRemove);

      if (issueToRemove) {
        RelatedIssuesService.remove(issueToRemove.relation_path)
          .then(res => res.json())
          .then(data => {
            this.store.setRelatedIssues(data.issuables);
          })
          .catch(res => {
            if (res && res.status !== 404) {
              Flash(relatedIssuesRemoveErrorMap[this.issuableType]);
            }
          });
      } else {
        Flash(pathIndeterminateErrorMap[this.issuableType]);
      }
    },
    onToggleAddRelatedIssuesForm() {
      this.isFormVisible = !this.isFormVisible;
    },
    onPendingIssueRemoveRequest(indexToRemove) {
      this.store.removePendingRelatedIssue(indexToRemove);
    },
    onPendingFormSubmit(newValue) {
      this.processAllReferences(newValue);

      if (this.state.pendingReferences.length > 0) {
        this.isSubmitting = true;
        this.service
          .addRelatedIssues(this.state.pendingReferences)
          .then(res => res.json())
          .then(data => {
            // We could potentially lose some pending issues in the interim here
            this.store.setPendingReferences([]);
            this.store.setRelatedIssues(data.issuables);

            this.isSubmitting = false;
            // Close the form on submission
            this.isFormVisible = false;
          })
          .catch(res => {
            this.isSubmitting = false;
            let errorMessage = addRelatedIssueErrorMap[this.issuableType];
            if (res.data && res.data.message) {
              errorMessage = res.data.message;
            }
            Flash(errorMessage);
          });
      }
    },
    onPendingFormCancel() {
      this.isFormVisible = false;
      this.store.setPendingReferences([]);
      this.inputValue = '';
    },
    fetchRelatedIssues() {
      this.isFetching = true;
      this.service
        .fetchRelatedIssues()
        .then(res => res.json())
        .then(issues => {
          this.store.setRelatedIssues(issues);
          this.isFetching = false;
        })
        .catch(() => {
          this.store.setRelatedIssues([]);
          this.isFetching = false;
          Flash('An error occurred while fetching issues.');
        });
    },
    saveIssueOrder({ issueId, beforeId, afterId, oldIndex, newIndex }) {
      const issueToReorder = _.find(this.state.relatedIssues, issue => issue.id === issueId);

      if (issueToReorder) {
        RelatedIssuesService.saveOrder({
          endpoint: issueToReorder.relation_path,
          move_before_id: beforeId,
          move_after_id: afterId,
        })
          .then(res => res.json())
          .then(res => {
            if (!res.message) {
              this.store.updateIssueOrder(oldIndex, newIndex);
            }
          })
          .catch(() => {
            Flash('An error occurred while reordering issues.');
          });
      }
    },
    onInput({ untouchedRawReferences, touchedReference }) {
      this.store.setPendingReferences(this.state.pendingReferences.concat(untouchedRawReferences));
      this.inputValue = `${touchedReference}`;
    },
    onBlur(newValue) {
      this.processAllReferences(newValue);
    },
    processAllReferences(value = '') {
      const rawReferences = value.split(/\s+/).filter(reference => reference.trim().length > 0);

      this.store.setPendingReferences(this.state.pendingReferences.concat(rawReferences));
      this.inputValue = '';
    },
  },
};
</script>

<template>
  <related-issues-block
    :class="cssClass"
    :help-path="helpPath"
    :is-fetching="isFetching"
    :is-submitting="isSubmitting"
    :related-issues="state.relatedIssues"
    :can-admin="canAdmin"
    :can-reorder="canReorder"
    :pending-references="state.pendingReferences"
    :is-form-visible="isFormVisible"
    :input-value="inputValue"
    :auto-complete-sources="autoCompleteSources"
    :title="title"
    :issuable-type="issuableType"
    :path-id-separator="pathIdSeparator"
    @saveReorder="saveIssueOrder"
    @toggleAddRelatedIssuesForm="onToggleAddRelatedIssuesForm"
    @addIssuableFormInput="onInput"
    @addIssuableFormBlur="onBlur"
    @addIssuableFormSubmit="onPendingFormSubmit"
    @addIssuableFormCancel="onPendingFormCancel"
    @pendingIssuableRemoveRequest="onPendingIssueRemoveRequest"
    @relatedIssueRemoveRequest="onRelatedIssueRemoveRequest"
  />
</template>

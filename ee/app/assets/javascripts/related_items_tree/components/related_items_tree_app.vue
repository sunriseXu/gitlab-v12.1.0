<script>
import { mapState, mapActions, mapGetters } from 'vuex';

import { GlLoadingIcon } from '@gitlab/ui';

import AddItemForm from 'ee/related_issues/components/add_issuable_form.vue';
import CreateItemForm from './create_item_form.vue';
import TreeItemRemoveModal from './tree_item_remove_modal.vue';

import RelatedItemsTreeHeader from './related_items_tree_header.vue';
import RelatedItemsTreeBody from './related_items_tree_body.vue';

import { PathIdSeparator, ActionType, OVERFLOW_AFTER } from '../constants';

export default {
  PathIdSeparator,
  ActionType,
  OVERFLOW_AFTER,
  components: {
    GlLoadingIcon,
    RelatedItemsTreeHeader,
    RelatedItemsTreeBody,
    AddItemForm,
    CreateItemForm,
    TreeItemRemoveModal,
  },
  computed: {
    ...mapState([
      'parentItem',
      'itemsFetchInProgress',
      'itemsFetchResultEmpty',
      'itemAddInProgress',
      'itemCreateInProgress',
      'showAddItemForm',
      'showCreateItemForm',
      'autoCompleteEpics',
      'autoCompleteIssues',
      'pendingReferences',
      'itemInputValue',
      'actionType',
      'epicsEndpoint',
      'issuesEndpoint',
    ]),
    ...mapGetters(['itemAutoCompleteSources', 'itemPathIdSeparator', 'directChildren']),
    disableContents() {
      return this.itemAddInProgress || this.itemCreateInProgress;
    },
  },
  mounted() {
    this.fetchItems({
      parentItem: this.parentItem,
    });
  },
  methods: {
    ...mapActions([
      'fetchItems',
      'toggleAddItemForm',
      'toggleCreateItemForm',
      'setPendingReferences',
      'addPendingReferences',
      'removePendingReference',
      'setItemInputValue',
      'addItem',
      'createItem',
    ]),
    getRawRefs(value) {
      return value.split(/\s+/).filter(ref => ref.trim().length > 0);
    },
    handlePendingItemRemove(index) {
      this.removePendingReference(index);
    },
    handleAddItemFormInput({ untouchedRawReferences, touchedReference }) {
      this.addPendingReferences(untouchedRawReferences);
      this.setItemInputValue(`${touchedReference}`);
    },
    handleAddItemFormBlur(newValue) {
      this.addPendingReferences(this.getRawRefs(newValue));
      this.setItemInputValue('');
    },
    handleAddItemFormSubmit(newValue) {
      this.handleAddItemFormBlur(newValue);

      if (this.pendingReferences.length > 0) {
        this.addItem();
      }
    },
    handleCreateItemFormSubmit(newValue) {
      this.createItem({
        itemTitle: newValue,
      });
    },
    handleAddItemFormCancel() {
      this.toggleAddItemForm({ toggleState: false, actionType: this.actionType });
      this.setPendingReferences([]);
      this.setItemInputValue('');
    },
    handleCreateItemFormCancel() {
      this.toggleCreateItemForm({ toggleState: false, actionType: this.actionType });
      this.setItemInputValue('');
    },
  },
};
</script>

<template>
  <div class="related-items-tree-container">
    <div v-if="itemsFetchInProgress" class="mt-2">
      <gl-loading-icon size="md" />
    </div>
    <div
      v-else
      class="related-items-tree card-slim mt-2"
      :class="{
        'disabled-content': disableContents,
        'overflow-auto': directChildren.length > $options.OVERFLOW_AFTER,
      }"
    >
      <related-items-tree-header :class="{ 'border-bottom-0': itemsFetchResultEmpty }" />
      <div v-if="showAddItemForm || showCreateItemForm" class="card-body add-item-form-container">
        <add-item-form
          v-if="showAddItemForm"
          :issuable-type="actionType"
          :input-value="itemInputValue"
          :is-submitting="itemAddInProgress"
          :pending-references="pendingReferences"
          :auto-complete-sources="itemAutoCompleteSources"
          :path-id-separator="itemPathIdSeparator"
          @pendingIssuableRemoveRequest="handlePendingItemRemove"
          @addIssuableFormInput="handleAddItemFormInput"
          @addIssuableFormBlur="handleAddItemFormBlur"
          @addIssuableFormSubmit="handleAddItemFormSubmit"
          @addIssuableFormCancel="handleAddItemFormCancel"
        />
        <create-item-form
          v-if="showCreateItemForm"
          :is-submitting="itemCreateInProgress"
          @createItemFormSubmit="handleCreateItemFormSubmit"
          @createItemFormCancel="handleCreateItemFormCancel"
        />
      </div>
      <related-items-tree-body
        v-if="!itemsFetchResultEmpty"
        :parent-item="parentItem"
        :children="directChildren"
      />
      <tree-item-remove-modal />
    </div>
  </div>
</template>

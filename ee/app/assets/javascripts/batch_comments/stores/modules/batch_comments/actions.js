import flash from '~/flash';
import { __ } from '~/locale';
import { scrollToElement } from '~/lib/utils/common_utils';
import service from '../../../services/drafts_service';
import * as types from './mutation_types';
import { CHANGES_TAB, DISCUSSION_TAB, SHOW_TAB } from '../../../constants';

export const enableBatchComments = ({ commit }) => {
  commit(types.ENABLE_BATCH_COMMENTS);
};

export const saveDraft = ({ dispatch }, draft) =>
  dispatch('saveNote', { ...draft, isDraft: true }, { root: true });

export const addDraftToDiscussion = ({ commit }, { endpoint, data }) =>
  service
    .addDraftToDiscussion(endpoint, data)
    .then(res => res.json())
    .then(res => {
      commit(types.ADD_NEW_DRAFT, res);
      return res;
    })
    .catch(() => {
      flash(__('An error occurred adding a draft to the thread.'));
    });

export const createNewDraft = ({ commit }, { endpoint, data }) =>
  service
    .createNewDraft(endpoint, data)
    .then(res => res.json())
    .then(res => {
      commit(types.ADD_NEW_DRAFT, res);
      return res;
    })
    .catch(() => {
      flash(__('An error occurred adding a new draft.'));
    });

export const deleteDraft = ({ commit, getters }, draft) =>
  service
    .deleteDraft(getters.getNotesData.draftsPath, draft.id)
    .then(() => {
      commit(types.DELETE_DRAFT, draft.id);
    })
    .catch(() => flash(__('An error occurred while deleting the comment')));

export const fetchDrafts = ({ commit, getters }) =>
  service
    .fetchDrafts(getters.getNotesData.draftsPath)
    .then(res => res.json())
    .then(data => commit(types.SET_BATCH_COMMENTS_DRAFTS, data))
    .catch(() => flash(__('An error occurred while fetching pending comments')));

export const publishSingleDraft = ({ commit, dispatch, getters }, draftId) => {
  commit(types.REQUEST_PUBLISH_DRAFT, draftId);

  service
    .publishDraft(getters.getNotesData.draftsPublishPath, draftId)
    .then(() => dispatch('updateDiscussionsAfterPublish'))
    .then(() => commit(types.RECEIVE_PUBLISH_DRAFT_SUCCESS, draftId))
    .catch(() => commit(types.RECEIVE_PUBLISH_DRAFT_ERROR, draftId));
};

export const publishReview = ({ commit, dispatch, getters }) => {
  commit(types.REQUEST_PUBLISH_REVIEW);

  return service
    .publish(getters.getNotesData.draftsPublishPath)
    .then(() => dispatch('updateDiscussionsAfterPublish'))
    .then(() => commit(types.RECEIVE_PUBLISH_REVIEW_SUCCESS))
    .catch(() => commit(types.RECEIVE_PUBLISH_REVIEW_ERROR));
};

export const updateDiscussionsAfterPublish = ({ dispatch, getters, rootGetters }) =>
  dispatch('fetchDiscussions', { path: getters.getNotesData.discussionsPath }, { root: true }).then(
    () =>
      dispatch('diffs/assignDiscussionsToDiff', rootGetters.discussionsStructuredByLineCode, {
        root: true,
      }),
  );

export const discardReview = ({ commit, getters }) => {
  commit(types.REQUEST_DISCARD_REVIEW);

  return service
    .discard(getters.getNotesData.draftsDiscardPath)
    .then(() => commit(types.RECEIVE_DISCARD_REVIEW_SUCCESS))
    .catch(() => commit(types.RECEIVE_DISCARD_REVIEW_ERROR));
};

export const updateDraft = ({ commit, getters }, { note, noteText, resolveDiscussion, callback }) =>
  service
    .update(getters.getNotesData.draftsPath, {
      draftId: note.id,
      note: noteText,
      resolveDiscussion,
    })
    .then(res => res.json())
    .then(data => commit(types.RECEIVE_DRAFT_UPDATE_SUCCESS, data))
    .then(callback)
    .catch(() => flash(__('An error occurred while updating the comment')));

export const scrollToDraft = ({ dispatch, rootGetters }, draft) => {
  const discussion = draft.discussion_id && rootGetters.getDiscussion(draft.discussion_id);
  const tab =
    draft.file_hash || (discussion && discussion.diff_discussion) ? CHANGES_TAB : SHOW_TAB;
  const tabEl = tab === CHANGES_TAB ? CHANGES_TAB : DISCUSSION_TAB;
  const draftID = `note_${draft.id}`;
  const el = document.querySelector(`#${tabEl} #${draftID}`);

  dispatch('closeReviewDropdown');

  window.location.hash = draftID;

  if (window.mrTabs.currentAction !== tab) {
    window.mrTabs.tabShown(tab);
  }

  if (discussion) {
    dispatch('expandDiscussion', { discussionId: discussion.id }, { root: true });
  }

  if (el) {
    setTimeout(() => scrollToElement(el.closest('.draft-note-component')));
  }
};

export const toggleReviewDropdown = ({ dispatch, state }) => {
  if (state.showPreviewDropdown) {
    dispatch('closeReviewDropdown');
  } else {
    dispatch('openReviewDropdown');
  }
};

export const openReviewDropdown = ({ commit }) => commit(types.OPEN_REVIEW_DROPDOWN);
export const closeReviewDropdown = ({ commit }) => commit(types.CLOSE_REVIEW_DROPDOWN);

export const expandAllDiscussions = ({ dispatch, state }) =>
  state.drafts
    .filter(draft => draft.discussion_id)
    .forEach(draft => {
      dispatch('expandDiscussion', { discussionId: draft.discussion_id }, { root: true });
    });

export const toggleResolveDiscussion = ({ commit }, draftId) => {
  commit(types.TOGGLE_RESOLVE_DISCUSSION, draftId);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

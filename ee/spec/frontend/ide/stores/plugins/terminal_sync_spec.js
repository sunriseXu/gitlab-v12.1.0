import eventHub from '~/ide/eventhub';
import { createStore } from '~/ide/stores';
import createTerminalPlugin from 'ee/ide/stores/plugins/terminal';
import createTerminalSyncPlugin from 'ee/ide/stores/plugins/terminal_sync';
import { SET_SESSION_STATUS } from 'ee/ide/stores/modules/terminal/mutation_types';
import { RUNNING, STOPPING } from 'ee/ide/constants';

jest.mock('ee/ide/lib/mirror');

const ACTION_START = 'terminalSync/start';
const ACTION_STOP = 'terminalSync/stop';
const ACTION_UPLOAD = 'terminalSync/upload';
const FILES_CHANGE_EVENT = 'ide.files.change';

describe('EE IDE stores/plugins/mirror', () => {
  let store;

  beforeEach(() => {
    const root = document.createElement('div');

    store = createStore();
    createTerminalPlugin(root)(store);

    store.dispatch = jest.fn(() => Promise.resolve());

    createTerminalSyncPlugin(root)(store);
  });

  it('does nothing on ide.files.change event', () => {
    eventHub.$emit(FILES_CHANGE_EVENT);

    expect(store.dispatch).not.toHaveBeenCalled();
  });

  describe('when session starts running', () => {
    beforeEach(() => {
      store.commit(`terminal/${SET_SESSION_STATUS}`, RUNNING);
    });

    it('starts', () => {
      expect(store.dispatch).toHaveBeenCalledWith(ACTION_START);
    });

    it('uploads when ide.files.change is emitted', () => {
      expect(store.dispatch).not.toHaveBeenCalledWith(ACTION_UPLOAD);

      eventHub.$emit(FILES_CHANGE_EVENT);

      jest.runAllTimers();

      expect(store.dispatch).toHaveBeenCalledWith(ACTION_UPLOAD);
    });

    describe('when session stops', () => {
      beforeEach(() => {
        store.commit(`terminal/${SET_SESSION_STATUS}`, STOPPING);
      });

      it('stops', () => {
        expect(store.dispatch).toHaveBeenCalledWith(ACTION_STOP);
      });

      it('does not upload anymore', () => {
        eventHub.$emit(FILES_CHANGE_EVENT);

        jest.runAllTimers();

        expect(store.dispatch).not.toHaveBeenCalledWith(ACTION_UPLOAD);
      });
    });
  });
});

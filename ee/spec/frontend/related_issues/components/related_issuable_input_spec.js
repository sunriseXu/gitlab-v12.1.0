import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { issuableTypesMap } from 'ee/related_issues/constants';
import RelatedIssuableInput from 'ee/related_issues/components/related_issuable_input.vue';

jest.mock('ee_else_ce/gfm_auto_complete', () => ({
  __esModule: true,
  default() {
    return {
      constructor() {},
      setup() {},
    };
  },
}));

describe('RelatedIssuableInput', () => {
  let propsData;

  beforeEach(() => {
    propsData = {
      inputValue: '',
      references: [],
      pathIdSeparator: '#',
      issuableType: issuableTypesMap.issue,
      autoCompleteSources: {
        issues: `${TEST_HOST}/h5bp/html5-boilerplate/-/autocomplete_sources/issues`,
      },
    };
  });

  describe('autocomplete', () => {
    describe('with autoCompleteSources', () => {
      it('shows placeholder text', () => {
        const wrapper = shallowMount(RelatedIssuableInput, { propsData });

        expect(wrapper.find({ ref: 'input' }).element.placeholder).toBe(
          'Paste issue link or <#issue id>',
        );
      });

      it('has GfmAutoComplete', () => {
        const wrapper = shallowMount(RelatedIssuableInput, { propsData });

        expect(wrapper.vm.gfmAutoComplete).toBeDefined();
      });
    });

    describe('with no autoCompleteSources', () => {
      it('shows placeholder text', () => {
        const wrapper = shallowMount(RelatedIssuableInput, {
          propsData: {
            ...propsData,
            references: ['!1', '!2'],
          },
        });

        expect(wrapper.find({ ref: 'input' }).element.value).toBe('');
      });

      it('does not have GfmAutoComplete', () => {
        const wrapper = shallowMount(RelatedIssuableInput, {
          propsData: {
            ...propsData,
            autoCompleteSources: {},
          },
        });

        expect(wrapper.vm.gfmAutoComplete).not.toBeDefined();
      });
    });
  });

  describe('focus', () => {
    it('when clicking anywhere on the input wrapper it should focus the input', () => {
      const wrapper = shallowMount(RelatedIssuableInput, {
        propsData: {
          ...propsData,
          references: ['foo', 'bar'],
        },
      });

      wrapper.find('li').trigger('click');

      expect(document.activeElement).toBe(wrapper.find({ ref: 'input' }).element);
    });
  });

  describe('when filling in the input', () => {
    it('emits addIssuableFormInput with data', () => {
      const wrapper = shallowMount(RelatedIssuableInput, {
        propsData,
      });

      wrapper.vm.$emit = jest.fn();

      const newInputValue = 'filling in things';
      const untouchedRawReferences = newInputValue.trim().split(/\s/);
      const touchedReference = untouchedRawReferences.pop();
      const input = wrapper.find({ ref: 'input' });

      input.element.value = newInputValue;
      input.element.selectionStart = newInputValue.length;
      input.element.selectionEnd = newInputValue.length;
      input.trigger('input');

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormInput', {
        newValue: newInputValue,
        caretPos: newInputValue.length,
        untouchedRawReferences,
        touchedReference,
      });
    });
  });
});

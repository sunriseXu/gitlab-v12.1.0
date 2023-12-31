import { shallowMount, createLocalVue } from '@vue/test-utils';
import MetricReportsIssueBody from 'ee/vue_shared/metrics_reports/components/metrics_reports_issue_body.vue';

const localVue = createLocalVue();

describe('Metrics reports issue body', () => {
  const Component = localVue.extend(MetricReportsIssueBody);
  let wrapper;

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('when metric did not change', () => {
    it('should render metric with no changes text', () => {
      wrapper = shallowMount(Component, {
        sync: false,
        localVue,
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');

      expect(metric.innerText.trim()).toEqual('name: value (No changes)');
    });
  });

  describe('when metric changed', () => {
    it('should render metric with change', () => {
      wrapper = shallowMount(Component, {
        sync: false,
        localVue,
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');

      expect(metric.innerText.trim()).toEqual('name: value (prev)');
    });
  });

  describe('when metric is new', () => {
    it('should render metric with new badge', () => {
      wrapper = shallowMount(Component, {
        sync: false,
        localVue,
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
            isNew: true,
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');
      const badge = wrapper.element.querySelector('.js-metrics-reports-issue-badge');

      expect(metric.innerText.trim()).toEqual('name: value');
      expect(badge.innerText.trim()).toEqual('New');
    });
  });

  describe('when metric was removed', () => {
    it('should render metric with removed badge', () => {
      wrapper = shallowMount(Component, {
        sync: false,
        localVue,
        propsData: {
          issue: {
            name: 'name',
            value: 'value',
            wasRemoved: true,
          },
        },
      });

      const metric = wrapper.element.querySelector('.js-metrics-reports-issue-text');
      const badge = wrapper.element.querySelector('.js-metrics-reports-issue-badge');

      expect(metric.innerText.trim()).toEqual('name: value');
      expect(badge.innerText.trim()).toEqual('Removed');
    });
  });
});

<script>
import { mapState, mapGetters } from 'vuex';
import { GlButton } from '@gitlab/ui';
import { LicenseCard, SkeletonLicenseCard } from './cards';

export default {
  name: 'LicenseCardsList',
  components: {
    LicenseCard,
    SkeletonLicenseCard,
    GlButton,
  },
  computed: {
    ...mapState(['licenses', 'isLoadingLicenses', 'newLicensePath']),
    ...mapGetters(['hasLicenses']),
  },
};
</script>

<template>
  <div>
    <div class="d-flex justify-content-between align-items-center">
      <h4>{{ __('Instance license') }}</h4>

      <gl-button class="my-3 js-add-license" variant="success" :href="newLicensePath">
        {{ __('Add license') }}
      </gl-button>
    </div>

    <ul class="license-list list-unstyled">
      <li v-if="isLoadingLicenses">
        <skeleton-license-card />
      </li>
      <li v-for="(license, index) in licenses" v-else-if="hasLicenses" :key="license.id">
        <license-card :license="license" :is-current-license="index === 0" />
      </li>
      <li v-else>
        <strong>
          {{ __('No licenses found.') }}
        </strong>
      </li>
    </ul>
  </div>
</template>

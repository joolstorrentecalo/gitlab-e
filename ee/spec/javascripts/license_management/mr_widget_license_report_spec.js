import Vue from 'vue';
import Vuex from 'vuex';

import LicenseManagement from 'ee/vue_shared/license_management/mr_widget_license_report.vue';
import { LOADING, ERROR, SUCCESS } from 'ee/vue_shared/security_reports/store/constants';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import {
  approvedLicense,
  blacklistedLicense,
  licenseReport as licenseReportMock,
} from 'ee_spec/license_management/mock_data';

describe('License Report MR Widget', () => {
  const Component = Vue.extend(LicenseManagement);
  const apiUrl = `${TEST_HOST}/license_management`;
  const securityApprovalsHelpPagePath = `${TEST_HOST}/path/to/security/approvals/help`;
  let vm;

  const defaultState = {
    managedLicenses: [approvedLicense, blacklistedLicense],
    currentLicenseInModal: licenseReportMock[0],
    isLoadingManagedLicenses: true,
  };

  const defaultGetters = {
    isLoading() {
      return false;
    },
    licenseReport() {
      return licenseReportMock;
    },
    licenseSummaryText() {
      return 'FOO';
    },
    reportContainsBlacklistedLicense() {
      return false;
    },
  };

  const defaultProps = {
    loadingText: 'LOADING',
    errorText: 'ERROR',
    headPath: `${TEST_HOST}/head.json`,
    basePath: `${TEST_HOST}/head.json`,
    licensesApiPath: `${TEST_HOST}/parsed_license_report.json`,
    canManageLicenses: true,
    licenseManagementSettingsPath: `${TEST_HOST}/lm_settings`,
    fullReportPath: `${TEST_HOST}/path/to/the/full/report`,
    apiUrl,
    securityApprovalsHelpPagePath,
  };

  const defaultActions = {
    setAPISettings: () => {},
    loadManagedLicenses: () => {},
    loadLicenseReport: () => {},
    loadParsedLicenseReport: () => {},
  };

  const mountComponent = ({
    props = defaultProps,
    getters = defaultGetters,
    state = defaultState,
    actions = defaultActions,
  } = {}) => {
    const store = new Vuex.Store({
      state,
      getters,
      actions,
    });
    return mountComponentWithStore(Component, { props, store });
  };

  beforeEach(() => {
    vm = mountComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with the `parsedLicenseReport` feature flag turned off', () => {
    beforeAll(() => {
      gon.features = gon.features || {};
      gon.features.parsedLicenseReport = false;
    });

    describe('computed', () => {
      describe('hasLicenseReportIssues', () => {
        it('should be false, if the report is empty', () => {
          const getters = {
            ...defaultGetters,
            licenseReport() {
              return [];
            },
          };
          vm = mountComponent({ getters });

          expect(vm.hasLicenseReportIssues).toBe(false);
        });

        it('should be true, if the report is not empty', () => {
          expect(vm.hasLicenseReportIssues).toBe(true);
        });
      });

      describe('licenseReportStatus', () => {
        it('should be `LOADING`, if the report is loading', () => {
          const getters = {
            ...defaultGetters,
            isLoading() {
              return true;
            },
          };
          vm = mountComponent({ getters });

          expect(vm.licenseReportStatus).toBe(LOADING);
        });

        it('should be `ERROR`, if the report is has an error', () => {
          const state = { ...defaultState, loadLicenseReportError: new Error('test') };
          vm = mountComponent({ state });

          expect(vm.licenseReportStatus).toBe(ERROR);
        });

        it('should be `SUCCESS`, if the report is successful', () => {
          expect(vm.licenseReportStatus).toBe(SUCCESS);
        });
      });

      describe('showActionButtons', () => {
        const { fullReportPath, licenseManagementSettingsPath, ...otherProps } = defaultProps;

        it('should be true if fullReportPath AND licenseManagementSettingsPath prop are provided', () => {
          const props = { ...otherProps, fullReportPath, licenseManagementSettingsPath };
          vm = mountComponent({ props });

          expect(vm.showActionButtons).toBe(true);
        });

        it('should be true if only licenseManagementSettingsPath is provided', () => {
          const props = { ...otherProps, fullReportPath: null, licenseManagementSettingsPath };
          vm = mountComponent({ props });

          expect(vm.showActionButtons).toBe(true);
        });

        it('should be true if only fullReportPath is provided', () => {
          const props = {
            ...otherProps,
            fullReportPath,
            licenseManagementSettingsPath: null,
          };
          vm = mountComponent({ props });

          expect(vm.showActionButtons).toBe(true);
        });

        it('should be false if fullReportPath and licenseManagementSettingsPath prop are not provided', () => {
          const props = {
            ...otherProps,
            fullReportPath: null,
            licenseManagementSettingsPath: null,
          };
          vm = mountComponent({ props });

          expect(vm.showActionButtons).toBe(false);
        });
      });
    });

    it('should render report section wrapper', () => {
      expect(vm.$el.querySelector('.license-report-widget')).not.toBeNull();
    });

    it('should render report widget section', () => {
      expect(vm.$el.querySelector('.report-block-container')).not.toBeNull();
    });

    describe('`View full report` button', () => {
      const selector = '.js-full-report';

      it('should be rendered when fullReportPath prop is provided', () => {
        const linkEl = vm.$el.querySelector(selector);

        expect(linkEl).not.toBeNull();
        expect(linkEl.getAttribute('href')).toEqual(defaultProps.fullReportPath);
        expect(linkEl.textContent.trim()).toEqual('View full report');
      });

      it('should not be rendered when fullReportPath prop is not provided', () => {
        const props = { ...defaultProps, fullReportPath: null };
        vm = mountComponent({ props });

        const linkEl = vm.$el.querySelector(selector);

        expect(linkEl).toBeNull();
      });
    });

    describe('`Manage licenses` button', () => {
      const selector = '.js-manage-licenses';

      it('should be rendered when licenseManagementSettingsPath prop is provided', () => {
        const linkEl = vm.$el.querySelector(selector);

        expect(linkEl).not.toBeNull();
        expect(linkEl.getAttribute('href')).toEqual(defaultProps.licenseManagementSettingsPath);
        expect(linkEl.textContent.trim()).toEqual('Manage licenses');
      });

      it('should not be rendered when licenseManagementSettingsPath prop is not provided', () => {
        const props = { ...defaultProps, licenseManagementSettingsPath: null };
        vm = mountComponent({ props });

        const linkEl = vm.$el.querySelector(selector);

        expect(linkEl).toBeNull();
      });
    });

    it('should render set approval modal', () => {
      expect(vm.$el.querySelector('#modal-set-license-approval')).not.toBeNull();
    });

    it('should init store after mount', () => {
      const actions = {
        setAPISettings: jasmine.createSpy('setAPISettings').and.callFake(() => {}),
        loadManagedLicenses: jasmine.createSpy('loadManagedLicenses').and.callFake(() => {}),
        loadLicenseReport: jasmine.createSpy('loadLicenseReport').and.callFake(() => {}),
        loadParsedLicenseReport: jasmine
          .createSpy('loadParsedLicenseReport')
          .and.callFake(() => {}),
      };
      vm = mountComponent({ actions });

      expect(actions.setAPISettings).toHaveBeenCalledWith(
        jasmine.any(Object),
        {
          apiUrlManageLicenses: apiUrl,
          headPath: defaultProps.headPath,
          basePath: defaultProps.basePath,
          licensesApiPath: defaultProps.licensesApiPath,
          canManageLicenses: true,
        },
        undefined,
      );

      expect(actions.loadManagedLicenses).toHaveBeenCalledWith(
        jasmine.any(Object),
        undefined,
        undefined,
      );

      expect(actions.loadLicenseReport).toHaveBeenCalledWith(
        jasmine.any(Object),
        undefined,
        undefined,
      );

      expect(actions.loadParsedLicenseReport).not.toHaveBeenCalled();
    });

    describe('approval status', () => {
      const findSecurityApprovalHelpLink = () =>
        vm.$el.querySelector('.js-security-approval-help-link');

      it('does not show a link to security approval help page if report does not contain blacklisted licenses', () => {
        expect(findSecurityApprovalHelpLink()).toBeNull();
      });

      it('shows a link to security approval help page if report contains blacklisted licenses', () => {
        const getters = {
          ...defaultGetters,
          reportContainsBlacklistedLicense() {
            return true;
          },
        };
        vm = mountComponent({ getters });
        const securityApprovalHelpLink = findSecurityApprovalHelpLink();

        expect(findSecurityApprovalHelpLink()).not.toBeNull();
        expect(securityApprovalHelpLink.getAttribute('href')).toEqual(
          securityApprovalsHelpPagePath,
        );
      });
    });
  });

  describe('with the `parsedLicenseReport` feature flag turned on', () => {
    beforeAll(() => {
      gon.features = gon.features || {};
      gon.features.parsedLicenseReport = true;
    });

    afterAll(() => {
      gon.features.parsedLicenseReport = false;
    });

    it('should load the reports from the backend API', () => {
      const actions = {
        setAPISettings: jasmine.createSpy('setAPISettings').and.callFake(() => {}),
        loadManagedLicenses: jasmine.createSpy('loadManagedLicenses').and.callFake(() => {}),
        loadLicenseReport: jasmine.createSpy('loadLicenseReport').and.callFake(() => {}),
        loadParsedLicenseReport: jasmine
          .createSpy('loadParsedLicenseReport')
          .and.callFake(() => {}),
      };
      vm = mountComponent({ actions });

      expect(actions.setAPISettings).toHaveBeenCalledWith(
        jasmine.any(Object),
        {
          apiUrlManageLicenses: apiUrl,
          headPath: defaultProps.headPath,
          basePath: defaultProps.basePath,
          licensesApiPath: defaultProps.licensesApiPath,
          canManageLicenses: true,
        },
        undefined,
      );

      expect(actions.loadParsedLicenseReport).toHaveBeenCalledWith(
        jasmine.any(Object),
        undefined,
        undefined,
      );

      expect(actions.loadLicenseReport).not.toHaveBeenCalled();

      expect(actions.loadManagedLicenses).not.toHaveBeenCalled();
    });
  });
});

import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import createState from 'ee/vue_shared/security_reports/store/state';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import { mount, shallowMount } from '@vue/test-utils';

describe('Security Reports modal', () => {
  let wrapper;

  const mountComponent = (options, mountFn = shallowMount) => {
    wrapper = mountFn(component, options);
  };

  describe('with permissions', () => {
    describe('with dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.isDismissed = true;
        propsData.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith', name: 'John Smith' },
          pipeline: { id: '123', path: '#' },
          created_at: new Date().toString(),
        };
        mountComponent({ propsData }, mount);
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(wrapper.text().trim()).toContain('John Smith');
        expect(wrapper.text().trim()).toContain('@jsmith');
        expect(wrapper.text().trim()).toContain('#123');
      });

      it('renders the dismissal comment placeholder', () => {
        expect(wrapper.find('.js-comment-placeholder')).not.toBeNull();
      });
    });

    describe('with about to be dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith', name: 'John Smith' },
          pipeline: { id: '123', path: '#' },
        };
        mountComponent({ propsData }, mount);
      });

      it('renders dismissal author and hides associated pipeline', () => {
        expect(wrapper.text().trim()).toContain('John Smith');
        expect(wrapper.text().trim()).toContain('@jsmith');
        expect(wrapper.text().trim()).not.toContain('#123');
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        mountComponent({ propsData }, mount);
      });

      it('allows the vulnerability to be dismissed', () => {
        expect(wrapper.find({ ref: 'footer' }).props('canDismissVulnerability')).toBe(true);
      });
    });

    describe('with merge request available', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canCreateIssue: true,
          canCreateMergeRequest: true,
        };
        const summary = 'Upgrade to 123';
        const diff = 'abc123';
        propsData.modal.vulnerability.remediations = [{ summary, diff }];
        mountComponent({ propsData }, mount);
      });

      it('renders create merge request and issue button as a split button', () => {
        expect(wrapper.contains('.js-split-button')).toBe(true);
        expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
        expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
      });

      describe('with merge request created', () => {
        it('renders the issue button as a single button', done => {
          const propsData = {
            modal: createState().modal,
            canCreateIssue: true,
            canCreateMergeRequest: true,
          };

          propsData.modal.vulnerability.hasMergeRequest = true;

          wrapper.setProps(propsData);

          Vue.nextTick()
            .then(() => {
              expect(wrapper.contains('.js-split-button')).toBe(false);
              expect(wrapper.contains('.js-action-button')).toBe(true);
              expect(wrapper.find('.js-action-button').text()).not.toContain(
                'Resolve with merge request',
              );
              expect(wrapper.find('.js-action-button').text()).toContain('Create issue');
              done();
            })
            .catch(done.fail);
        });
      });
    });

    describe('data', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          vulnerabilityFeedbackHelpPath: 'feedbacksHelpPath',
        };
        propsData.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        mountComponent({ propsData }, mount);
      });

      it('renders title', () => {
        expect(wrapper.text()).toContain('Arbitrary file existence disclosure in Action Pack');
      });

      it('renders help link', () => {
        expect(wrapper.find('.js-link-vulnerabilityFeedbackHelpPath').attributes('href')).toBe(
          'feedbacksHelpPath#solutions-for-vulnerabilities-auto-remediation',
        );
      });
    });

    describe('with a resolved issue', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
          canCreateIssue: true,
          canCreateMergeRequest: true,
          canDismissVulnerability: true,
        };
        propsData.modal.vulnerability.remediations = [{ diff: '123' }];
        propsData.modal.isResolved = true;
        mountComponent({ propsData });
      });

      it('disallows any actions in the footer', () => {
        expect(wrapper.find({ ref: 'footer' }).props()).toMatchObject({
          canCreateIssue: false,
          canCreateMergeRequest: false,
          canDownloadPatch: false,
          canDismissVulnerability: false,
        });
      });
    });
  });

  describe('without permissions', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      mountComponent({ propsData });
    });

    it('disallows any actions in the footer', () => {
      expect(wrapper.find({ ref: 'footer' }).props()).toMatchObject({
        canCreateIssue: false,
        canCreateMergeRequest: false,
        canDownloadPatch: false,
        canDismissVulnerability: false,
      });
    });
  });

  describe('related issue read access', () => {
    describe('with permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.issue_feedback = {
          issue_url: 'http://issue.url',
        };
        mountComponent({ propsData });
      });

      it('displays a link to the issue', () => {
        const notes = wrapper.find('.notes');
        expect(notes.exists()).toBe(true);
      });
    });

    describe('without permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.issue_feedback = {
          issue_url: null,
        };
        mountComponent({ propsData });
      });

      it('hides the link to the issue', () => {
        const notes = wrapper.find('.notes');
        expect(notes.exists()).toBe(false);
      });
    });
  });

  describe('related merge request read access', () => {
    describe('with permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.merge_request_feedback = {
          merge_request_path: 'http://mr.url',
        };
        mountComponent({ propsData });
      });

      it('displays a link to the merge request', () => {
        const notes = wrapper.find('.notes');
        expect(notes.exists()).toBe(true);
      });
    });

    describe('without permission to read', () => {
      beforeEach(() => {
        const propsData = {
          modal: createState().modal,
        };

        propsData.modal.vulnerability.merge_request_feedback = {
          merge_request_path: null,
        };
        mountComponent({ propsData });
      });

      it('hides the link to the merge request', () => {
        const notes = wrapper.find('.notes');
        expect(notes.exists()).toBe(false);
      });
    });
  });

  describe('with a resolved issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      propsData.modal.isResolved = true;
      mountComponent({ propsData });
    });

    it('disallows any actions in the footer', () => {
      expect(wrapper.find({ ref: 'footer' }).props()).toMatchObject({
        canCreateIssue: false,
        canCreateMergeRequest: false,
        canDownloadPatch: false,
        canDismissVulnerability: false,
      });
    });
  });

  describe('Vulnerability Details', () => {
    const blobPath = '/group/project/blob/1ab2c3d4e5/some/file.path#L0-0';
    const namespaceValue = 'foobar';
    const fileValue = '/some/file.path';

    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
      };
      propsData.modal.vulnerability.blob_path = blobPath;
      propsData.modal.data.namespace.value = namespaceValue;
      propsData.modal.data.file.value = fileValue;
      mountComponent({ propsData }, mount);
    });

    it('is rendered', () => {
      const vulnerabilityDetails = wrapper.find('.js-vulnerability-details');

      expect(vulnerabilityDetails.exists()).toBe(true);
      expect(vulnerabilityDetails.text()).toContain('foobar');
    });

    it('computes valued fields properly', () => {
      expect(wrapper.vm.valuedFields).toMatchObject({
        file: {
          value: fileValue,
          url: blobPath,
          isLink: true,
          text: 'File',
        },
        namespace: {
          value: namespaceValue,
          text: 'Namespace',
          isLink: false,
        },
      });
    });
  });

  describe('Solution Card', () => {
    it('is rendered if the vulnerability has a solution', () => {
      const propsData = {
        modal: createState().modal,
      };

      const solution = 'Upgrade to XYZ';
      propsData.modal.vulnerability.solution = solution;
      mountComponent({ propsData }, mount);

      const solutionCard = wrapper.find(SolutionCard);

      expect(solutionCard.exists()).toBe(true);
      expect(solutionCard.text()).toContain(solution);
      expect(wrapper.contains('hr')).toBe(false);
    });

    it('is rendered if the vulnerability has a remediation', () => {
      const propsData = {
        modal: createState().modal,
      };
      const summary = 'Upgrade to 123';
      const diff = 'foo';
      propsData.modal.vulnerability.remediations = [{ summary, diff }];
      mountComponent({ propsData }, mount);

      const solutionCard = wrapper.find(SolutionCard);

      expect(solutionCard.exists()).toBe(true);
      expect(solutionCard.text()).toContain(summary);
      expect(solutionCard.props('hasDownload')).toBe(true);
      expect(wrapper.contains('hr')).toBe(false);
    });

    it('is rendered if the vulnerability has neither a remediation nor a solution', () => {
      const propsData = {
        modal: createState().modal,
      };
      mountComponent({ propsData }, mount);

      const solutionCard = wrapper.find(SolutionCard);

      expect(solutionCard.exists()).toBe(true);
      expect(wrapper.contains('hr')).toBe(false);
    });
  });

  describe('add dismissal comment', () => {
    const comment = "Pirates don't eat the tourists";
    let propsData;

    beforeEach(() => {
      propsData = {
        modal: createState().modal,
      };

      propsData.modal.isCommentingOnDismissal = true;
    });

    beforeAll(() => {
      // https://github.com/vuejs/vue-test-utils/issues/532#issuecomment-398449786
      Vue.config.silent = true;
    });

    afterAll(() => {
      Vue.config.silent = false;
    });

    describe('with a non-dismissed vulnerability', () => {
      beforeEach(() => {
        mountComponent({ propsData });
      });

      it('creates an error when an empty comment is submitted', () => {
        const { vm } = wrapper;
        vm.handleDismissalCommentSubmission();

        expect(vm.dismissalCommentErrorMessage).toBe('Please add a comment in the text area above');
      });

      it('submits the comment and dismisses the vulnerability if text has been entered', () => {
        const { vm } = wrapper;
        vm.addCommentAndDismiss = jasmine.createSpy();
        vm.localDismissalComment = comment;
        vm.handleDismissalCommentSubmission();

        expect(vm.addCommentAndDismiss).toHaveBeenCalled();
        expect(vm.dismissalCommentErrorMessage).toBe('');
      });
    });

    describe('with a dismissed vulnerability', () => {
      beforeEach(() => {
        propsData.modal.vulnerability.dismissal_feedback = { author: {} };
        mountComponent({ propsData });
      });

      it('creates an error when an empty comment is submitted', () => {
        const { vm } = wrapper;
        vm.handleDismissalCommentSubmission();

        expect(vm.dismissalCommentErrorMessage).toBe('Please add a comment in the text area above');
      });

      it('submits the comment if text is entered and the vulnerability is already dismissed', () => {
        const { vm } = wrapper;
        vm.addDismissalComment = jasmine.createSpy();
        vm.localDismissalComment = comment;
        vm.handleDismissalCommentSubmission();

        expect(vm.addDismissalComment).toHaveBeenCalled();
        expect(vm.dismissalCommentErrorMessage).toBe('');
      });
    });
  });
});

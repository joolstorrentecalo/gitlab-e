import { shallowMount, mount } from '@vue/test-utils';
import eventHub from 'ee/projects/settings_service_desk/event_hub';
import ServiceDeskSetting from 'ee/projects/settings_service_desk/components/service_desk_setting.vue';

describe('ServiceDeskSetting', () => {
  let wrapper;

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findTemplateDropdown = () => wrapper.find('#service-desk-template-select');

  describe('when isEnabled=true', () => {
    describe('only isEnabled', () => {
      describe('as project admin', () => {
        beforeEach(() => {
          wrapper = shallowMount(ServiceDeskSetting, {
            propsData: {
              isEnabled: true,
            },
          });
        });

        it('should see activation checkbox', () => {
          expect(wrapper.contains('#service-desk-checkbox')).toBe(true);
        });

        it('should see main panel with the email info', () => {
          expect(wrapper.contains('#incoming-email-describer')).toBe(true);
        });

        it('should see loading spinner and not the incoming email', () => {
          expect(wrapper.contains('.fa-spinner')).toBe(true);
          expect(wrapper.contains('.incoming-email')).toBe(false);
        });
      });
    });

    describe('service desk toggle', () => {
      it('emits an event to turn on Service Desk when clicked', () => {
        const eventSpy = jest.fn();
        eventHub.$on('serviceDeskEnabledCheckboxToggled', eventSpy);

        wrapper = mount(ServiceDeskSetting, {
          propsData: {
            isEnabled: false,
          },
        });

        wrapper.find('#service-desk-checkbox').trigger('click');

        expect(eventSpy).toHaveBeenCalledWith(true);

        eventHub.$off('serviceDeskEnabledCheckboxToggled', eventSpy);
        eventSpy.mockRestore();
      });
    });

    describe('with incomingEmail', () => {
      const incomingEmail = 'foo@bar.com';

      beforeEach(() => {
        wrapper = mount(ServiceDeskSetting, {
          propsData: {
            isEnabled: true,
            incomingEmail,
          },
        });
      });

      it('should see email and not the loading spinner', () => {
        expect(wrapper.find('.incoming-email').element.value).toEqual(incomingEmail);
        expect(wrapper.contains('.fa-spinner')).toBe(false);
      });

      it('renders a copy to clipboard button', () => {
        expect(wrapper.contains('.qa-clipboard-button')).toBe(true);
        expect(wrapper.find('.qa-clipboard-button').element.dataset.clipboardText).toBe(
          incomingEmail,
        );
      });
    });

    describe('templates dropdown', () => {
      it('renders a dropdown to choose a template', () => {
        wrapper = shallowMount(ServiceDeskSetting, {
          propsData: {
            isEnabled: true,
          },
        });

        expect(wrapper.contains('#service-desk-template-select')).toBe(true);
      });

      it('renders a dropdown with a default value of ""', () => {
        wrapper = mount(ServiceDeskSetting, {
          propsData: {
            isEnabled: true,
          },
        });

        expect(findTemplateDropdown().element.value).toEqual('');
      });

      it('renders a dropdown with a value of "Bug" when it is the initial value', () => {
        const templates = ['Bug', 'Documentation', 'Security release'];

        wrapper = mount(ServiceDeskSetting, {
          propsData: {
            isEnabled: true,
            initialSelectedTemplate: 'Bug',
            templates,
          },
        });

        expect(findTemplateDropdown().element.value).toEqual('Bug');
      });

      it('renders a dropdown with no options when the project has no templates', () => {
        wrapper = mount(ServiceDeskSetting, {
          propsData: {
            isEnabled: true,
            templates: [],
          },
        });

        // The dropdown by default has one empty option
        expect(findTemplateDropdown().element.children.length).toEqual(1);
      });

      it('renders a dropdown with options when the project has templates', () => {
        const templates = ['Bug', 'Documentation', 'Security release'];
        wrapper = mount(ServiceDeskSetting, {
          propsData: {
            isEnabled: true,
            templates,
          },
        });

        // An empty-named template is prepended so the user can select no template
        const expectedTemplates = [''].concat(templates);

        const dropdown = findTemplateDropdown();
        const dropdownList = Array.from(dropdown.element.children).map(option => option.innerText);

        expect(dropdown.element.children.length).toEqual(expectedTemplates.length);
        expect(dropdownList.includes('Bug')).toEqual(true);
        expect(dropdownList.includes('Documentation')).toEqual(true);
        expect(dropdownList.includes('Security release')).toEqual(true);
      });
    });
  });

  describe('save button', () => {
    it('renders a save button to save a template', () => {
      wrapper = mount(ServiceDeskSetting, {
        propsData: {
          isEnabled: true,
        },
      });

      expect(wrapper.find('button.btn-success').text()).toContain('Save template');
    });

    it('emits a save event with the chosen template when the save button is clicked', () => {
      const eventSpy = jest.fn();
      eventHub.$on('serviceDeskTemplateSave', eventSpy);

      wrapper = mount(ServiceDeskSetting, {
        propsData: {
          isEnabled: true,
          initialSelectedTemplate: 'Bug',
        },
      });

      wrapper.find('button.btn-success').trigger('click');

      expect(eventSpy).toHaveBeenCalledWith('Bug');

      eventHub.$off('serviceDeskTemplateSave', eventSpy);
      eventSpy.mockRestore();
    });
  });

  describe('when isEnabled=false', () => {
    beforeEach(() => {
      wrapper = shallowMount(ServiceDeskSetting, {
        propsData: {
          isEnabled: false,
        },
      });
    });

    it('does not render email panel', () => {
      expect(wrapper.contains('#incoming-email-describer')).toBe(false);
    });

    it('does not render template dropdown', () => {
      expect(wrapper.contains('#service-desk-template-select')).toBe(false);
    });

    it('does not render template save button', () => {
      expect(wrapper.contains('button.btn-success')).toBe(false);
    });

    it('emits an event to turn on Service Desk when the toggle is clicked', () => {
      const eventSpy = jest.fn();
      eventHub.$on('serviceDeskEnabledCheckboxToggled', eventSpy);

      wrapper = mount(ServiceDeskSetting, {
        propsData: {
          isEnabled: true,
        },
      });

      wrapper.find('#service-desk-checkbox').trigger('click');

      expect(eventSpy).toHaveBeenCalledWith(false);

      eventHub.$off('serviceDeskEnabledCheckboxToggled', eventSpy);
      eventSpy.mockRestore();
    });
  });
});

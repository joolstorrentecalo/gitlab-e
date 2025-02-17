# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::ApprovalService do
  describe '#execute' do
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:project)       { merge_request.project }
    let!(:todo)         { create(:todo, user: user, project: project, target: merge_request) }

    subject(:service) { described_class.new(project, user) }

    context 'with invalid approval' do
      before do
        allow(merge_request.approvals).to receive(:new).and_return(double(save: false))
      end

      it 'does not create an approval note' do
        expect(SystemNoteService).not_to receive(:approve_mr)

        service.execute(merge_request)
      end

      it 'does not mark pending todos as done' do
        service.execute(merge_request)

        expect(todo.reload).to be_pending
      end
    end

    context 'with valid approval' do
      it 'creates an approval note' do
        allow(merge_request).to receive(:approvals_left).and_return(1)

        expect(SystemNoteService).to receive(:approve_mr).with(merge_request, user)

        service.execute(merge_request)
      end

      it 'marks pending todos as done' do
        allow(merge_request).to receive(:approvals_left).and_return(1)

        service.execute(merge_request)

        expect(todo.reload).to be_done
      end

      it 'resets the cache for approvals' do
        expect(merge_request).to receive(:reset_approval_cache!)

        service.execute(merge_request)
      end

      context 'with remaining approvals' do
        it 'fires an approval webhook' do
          expect(merge_request).to receive(:approvals_left).and_return(5)
          expect(service).to receive(:execute_hooks).with(merge_request, 'approval')

          service.execute(merge_request)
        end

        it 'does not send an email' do
          expect(merge_request).to receive(:approvals_left).and_return(5)
          expect(service).not_to receive(:notification_service)

          service.execute(merge_request)
        end
      end

      context 'with required approvals' do
        let(:notification_service) { NotificationService.new }

        before do
          expect(merge_request).to receive(:approvals_left).and_return(0)
          allow(service).to receive(:execute_hooks)
          allow(service).to receive(:notification_service).and_return(notification_service)
        end

        it 'fires an approved webhook' do
          expect(service).to receive(:execute_hooks).with(merge_request, 'approved')

          service.execute(merge_request)
        end

        it 'sends an email' do
          expect(notification_service).to receive_message_chain(:async, :approve_mr).with(merge_request, user)

          service.execute(merge_request)
        end
      end
    end

    context 'when project requires force auth for approval' do
      before do
        project.update(require_password_to_approve: true)
        user.update(password: 'password')
      end
      context 'when password not specified' do
        it 'raises an error' do
          expect { service.execute(merge_request) }.to raise_error(::MergeRequests::ApprovalService::IncorrectApprovalPasswordError)
        end
      end

      context 'when incorrect password is specified' do
        let(:params) do
          { approval_password: 'incorrect' }
        end

        it 'raises an error' do
          service_with_params = described_class.new(project, user, params)
          expect { service_with_params.execute(merge_request) }.to raise_error(::MergeRequests::ApprovalService::IncorrectApprovalPasswordError)
        end
      end

      context 'when correct password is specified' do
        let(:params) do
          { approval_password: 'password' }
        end

        it 'does not raise an error' do
          service_with_params = described_class.new(project, user, params)
          expect { service_with_params.execute(merge_request) }.not_to raise_error(::MergeRequests::ApprovalService::IncorrectApprovalPasswordError)
        end
      end
    end
  end
end

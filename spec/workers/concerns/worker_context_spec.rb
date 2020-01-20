# frozen_string_literal: true

require 'spec_helper'

describe WorkerContext do
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker # and thus also `WorkerContext`.
    end
  end

  shared_examples 'tracking bulk scheduling contexts' do
    let(:arguments_with_contexts) do
      worker.__send__(:batch_scheduling_contexts)
    end

    it 'keeps track of the context per key to schedule' do
      # stub clearing the contexts, so we can check what's inside
      allow(arguments_with_contexts).to receive(:clear)

      subject

      expect(worker.context_for_arguments(["hello"])).to be_a(Gitlab::ApplicationContext)
    end

    it 'clears the contexts' do
      subject

      expect(arguments_with_contexts).to be_empty
    end
  end

  describe '.bulk_perform_async_with_contexts' do
    subject do
      worker.bulk_perform_async_with_contexts(["hello"] => { user: build_stubbed(:user) }, ["world"] => {})
    end

    it 'calls bulk_perform_async with the arguments' do
      expect(worker).to receive(:bulk_perform_async).with([["hello"], ["world"]])

      subject
    end

    it_behaves_like 'tracking bulk scheduling contexts'
  end

  describe '.bulk_perform_in_with_contexts' do
    subject do
      worker.bulk_perform_in_with_contexts(10.minutes, ["hello"] => { user: build_stubbed(:user) }, ["world"] => {})
    end

    it 'calls bulk_perform_in with the arguments and delay' do
      expect(worker).to receive(:bulk_perform_in).with(10.minutes, [["hello"], ["world"]])

      subject
    end

    it_behaves_like 'tracking bulk scheduling contexts'
  end

  describe '.worker_context' do
    it 'allows modifying the context for the entire worker' do
      worker.worker_context(user: build_stubbed(:user))

      expect(worker.get_worker_context).to be_a(Gitlab::ApplicationContext)
    end
  end

  describe '#with_context' do
    it 'allows modifying context when the job is running' do
      worker.new.with_context(user: build_stubbed(:user, username: 'jane-doe')) do
        expect(Labkit::Context.current.to_h).to include('meta.user' => 'jane-doe')
      end
    end
  end
end

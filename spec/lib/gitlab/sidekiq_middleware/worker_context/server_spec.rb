# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::WorkerContext::Server do
  class TestWorker
    # To keep track of the context that was active for certain arguments
    cattr_accessor(:contexts) { {} }

    include ApplicationWorker

    worker_context user: nil

    def perform(identifier, *args)
      self.class.contexts.merge!(identifier => Labkit::Context.current.to_h)
    end
  end

  before do
    TestWorker.contexts.clear
  end

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  before(:context) do
    Sidekiq::Testing.server_middleware do |chain|
      chain.add described_class
    end
  end

  after(:context) do
    Sidekiq::Testing.server_middleware do |chain|
      chain.remove described_class
    end
  end

  describe "#call" do
    it 'applies a class context' do
      Gitlab::ApplicationContext.with_context(user: build_stubbed(:user)) do
        TestWorker.perform_async("identifier", 1)
      end

      expect(TestWorker.contexts['identifier'].keys).not_to include('meta.user')
    end
  end
end

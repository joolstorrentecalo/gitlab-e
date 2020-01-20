# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::WorkerContext::Client do
  class TestWorker
    include ApplicationWorker

    def self.job_for_args(args)
      jobs.find { |job| job['args'] == args }
    end

    def perform(*args)
    end
  end

  describe "#call" do
    it 'applies a context for jobs scheduled in batch' do
      user_1 = build_stubbed(:user, username: "user-1")
      user_2 = build_stubbed(:user, username: "user-2")

      TestWorker.bulk_perform_async_with_contexts(
        ['job1', 1, 2, 3] => { user: user_1 },
        ['job2', 1, 2, 3] => { user: user_2 }
      )

      job1 = TestWorker.job_for_args(['job1', 1, 2, 3])
      job2 = TestWorker.job_for_args(['job2', 1, 2, 3])

      expect(job1['meta.user']).to eq(user_1.username)
      expect(job2['meta.user']).to eq(user_2.username)
    end
  end
end

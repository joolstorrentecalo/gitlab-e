# frozen_string_literal: true

class SpamService
  include AkismetMethods

  attr_accessor :spammable, :request, :options
  attr_reader :spam_log

  def initialize(spammable:, request:)
    @spammable = spammable
    @request = request
    @options = {}

    if @request
      @options[:ip_address] = @request.env['action_dispatch.remote_ip'].to_s
      @options[:user_agent] = @request.env['HTTP_USER_AGENT']
      @options[:referrer] = @request.env['HTTP_REFERRER']
    else
      @options[:ip_address] = @spammable.ip_address
      @options[:user_agent] = @spammable.user_agent
    end
  end

  def when_recaptcha_verified(recaptcha_verified, api = false)
    # In case it's a request which is already verified through recaptcha, yield
    # block.
    if recaptcha_verified
      yield
    else
      # Otherwise, it goes to Akismet and check if it's a spam. If that's the
      # case, it assigns spammable record as "spam" and create a SpamLog record.
      possible_spam = check(api)
      spammable.spam = possible_spam unless spammable.allow_possible_spam?
      spammable.spam_log = spam_log
    end
  end

  private

  def check(api)
    return false unless request && check_for_spam?

    return false unless akismet.spam?

    create_spam_log(api)
    true
  end

  def check_for_spam?
    spammable.check_for_spam?
  end

  def create_spam_log(api)
    @spam_log = SpamLog.create!(
      {
        user_id: spammable.author_id,
        title: spammable.spam_title,
        description: spammable.spam_description,
        source_ip: options[:ip_address],
        user_agent: options[:user_agent],
        noteable_type: spammable.class.to_s,
        via_api: api
      }
    )
  end
end

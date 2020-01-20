# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../support/helpers/expect_offense'
require_relative '../../../../rubocop/cop/scalability/bulk_perform_with_context'

describe RuboCop::Cop::Scalability::BulkPerformWithContext do
  include CopHelper
  include ExpectOffense

  subject(:cop) { described_class.new }

  it "adds an offense when calling bulk_perform_async" do
    inspect_source(<<~CODE.strip_indent)
      Worker.bulk_perform_async(args)
    CODE

    expect(cop.offenses.size).to eq(1)
  end

  it "adds an offense when calling bulk_perform_in" do
    inspect_source(<<~CODE.strip_indent)
      Worker.bulk_perform_in(args)
    CODE

    expect(cop.offenses.size).to eq(1)
  end
end

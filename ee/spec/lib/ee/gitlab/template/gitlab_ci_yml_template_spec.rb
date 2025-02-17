# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Template::GitlabCiYmlTemplate do
  describe '.all' do
    let(:templates) { described_class.all.map(&:name) }

    it 'finds the Security Products templates' do
      expect(templates).to include('Container-Scanning')
      expect(templates).to include('DAST')
      expect(templates).to include('Dependency-Scanning')
      expect(templates).to include('License-Management')
      expect(templates).to include('SAST')
    end

    it 'finds the Verify templates' do
      expect(templates).to include('Browser-Performance')
    end
  end
end

# frozen_string_literal: true
require 'spec_helper'

describe Packages::Npm::CreatePackageService do
  let(:namespace) {create(:namespace)}
  let(:project) { create(:project, namespace: namespace) }
  let(:user) { create(:user) }
  let(:version) { '1.0.1'.freeze }

  let(:params) do
    JSON.parse(
      fixture_file('npm/payload.json', dir: 'ee')
        .gsub('@root/npm-test', package_name)
        .gsub('1.0.1', version)
    ).with_indifferent_access
      .merge!(override)
  end
  let(:override) { {} }
  let(:package_name) { "@#{namespace.path}/my-app".freeze }

  subject { described_class.new(project, user, params).execute }

  shared_examples 'valid package' do
    it 'creates a package' do
      expect { subject }
        .to change { Packages::Package.count }.by(1)
        .and change { Packages::Package.npm.count }.by(1)
        .and change { Packages::Tag.count }.by(1)
    end

    it { is_expected.to be_valid }

    it 'creates a package with name and version' do
      package = subject

      expect(package.name).to eq(package_name)
      expect(package.version).to eq(version)
    end

    it { is_expected.to be_valid }
    it { expect(subject.name).to eq(package_name) }
    it { expect(subject.version).to eq(version) }
  end

  describe '#execute' do
    context 'scoped package' do
      it_behaves_like 'valid package'

      it_behaves_like 'assigns build to package'
    end

    context 'invalid package name' do
      let(:package_name) { "@#{namespace.path}/my-group/my-app".freeze }

      it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid) }
    end

    context 'package already exists' do
      let(:package_name) { "@#{namespace.path}/my_package" }
      let!(:existing_package) { create(:npm_package, project: project, name: package_name, version: '1.0.1') }

      it { expect(subject[:http_status]).to eq 403 }
      it { expect(subject[:message]).to be 'Package already exists.' }
    end

    context 'with incorrect namespace' do
      let(:package_name) { '@my_other_namespace/my-app' }

      it 'raises a RecordInvalid error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with empty versions' do
      let(:override) { { versions: {} } }

      it { expect(subject[:http_status]).to eq 400 }
      it { expect(subject[:message]).to eq 'Version is empty.' }
    end
  end
end

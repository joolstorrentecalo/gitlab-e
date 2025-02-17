# frozen_string_literal: true

require 'spec_helper'

describe ImportSoftwareLicensesWorker do
  let(:catalogue) { build(:spdx_catalogue) }
  let(:spdx_apache_license) { build(:spdx_license, :apache_1) }
  let(:spdx_bsd_license) { build(:spdx_license, :bsd) }
  let(:spdx_mit_license) { build(:spdx_license, :mit) }

  before do
    allow(Gitlab::SPDX::Catalogue).to receive(:latest).and_return(catalogue)
    allow(catalogue).to receive(:each)
      .and_yield(spdx_apache_license)
      .and_yield(spdx_bsd_license)
      .and_yield(spdx_mit_license)
  end

  describe '#perform' do
    let!(:apache) { create(:software_license, name: spdx_apache_license.name, spdx_identifier: nil) }
    let!(:mit) { create(:software_license, name: spdx_mit_license.name, spdx_identifier: spdx_mit_license.id) }

    context 'when the licenses.json endpoint is healthy' do
      before do
        subject.perform
      end

      it { expect(apache.reload.spdx_identifier).to eql(spdx_apache_license.id) }
      it { expect(SoftwareLicense.count).to eq(3) }
      it { expect(SoftwareLicense.pluck(:spdx_identifier)).to contain_exactly(spdx_apache_license.id, spdx_mit_license.id, spdx_bsd_license.id) }
      it { expect(SoftwareLicense.pluck(:name)).to contain_exactly(spdx_apache_license.name, spdx_mit_license.name, spdx_bsd_license.name) }
    end

    context 'when run multiple times' do
      it 'does not create duplicated software licenses' do
        subject.perform

        expect(SoftwareLicense.count).to eq(3)
        expect { subject.perform }.not_to change(SoftwareLicense, :count)
      end
    end
  end
end

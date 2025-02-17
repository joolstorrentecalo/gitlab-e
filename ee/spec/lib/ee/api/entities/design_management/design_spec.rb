# frozen_string_literal: true

require 'spec_helper'

describe EE::API::Entities::DesignManagement::Design do
  set(:design) { create(:design) }
  let(:entity) { described_class.new(design, request: double) }

  subject { entity.as_json }

  it 'has the correct attributes' do
    expect(subject).to eq({
      id: design.id,
      project_id: design.project_id,
      filename: design.filename,
      image_url: ::Gitlab::UrlBuilder.build(design)
    })
  end
end

# frozen_string_literal: true
module Packages
  module Npm
    class CreatePackageService < BaseService
      include Gitlab::Utils::StrongMemoize

      def execute
        return error('Version is empty.', 400) if version.blank?
        return error('Package already exists.', 403) if current_package_exists?

        ActiveRecord::Base.transaction { create_package! }
      end

      private

      def create_package!
        package = project.packages.create!(
          name: name,
          version: version,
          package_type: 'npm'
        )

        if build.present?
          package.create_build_info!(pipeline: build.pipeline)
        end

        ::Packages::CreatePackageFileService.new(package, file_params).execute
        ::Packages::CreateDependencyService.new(package, package_dependencies).execute
        ::Packages::Npm::CreateTagService.new(package, dist_tag).execute

        package
      end

      def current_package_exists?
        project.packages
               .npm
               .with_name(name)
               .with_version(version)
               .exists?
      end

      def name
        params[:name]
      end

      def version
        strong_memoize(:version) do
          params[:versions].keys.first
        end
      end

      def version_data
        params[:versions][version]
      end

      def build
        params[:build]
      end

      def dist_tag
        params['dist-tags'].keys.first
      end

      def package_file_name
        strong_memoize(:package_file_name) do
          "#{name}-#{version}.tgz"
        end
      end

      def attachment
        strong_memoize(:attachment) do
          params['_attachments'][package_file_name]
        end
      end

      def file_params
        {
          file:      CarrierWaveStringFile.new(Base64.decode64(attachment['data'])),
          size:      attachment['length'],
          file_sha1: version_data[:dist][:shasum],
          file_name: package_file_name
        }
      end

      def package_dependencies
        _version, versions_data = params[:versions].first
        versions_data
      end
    end
  end
end

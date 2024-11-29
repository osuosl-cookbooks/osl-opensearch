module OslOpensearch
  module Cookbook
    module Helpers
      # OpenSearch methods
      def osl_opensearch_secrets
        data_bag_item('opensearch', 'secrets')
      end

      def osl_install_opensearch_gem
        return if gem_installed?('opensearch-ruby')
        declare_resource(:chef_gem, 'opensearch-ruby') do
          options build_options
          version '~> 3.4'
          compile_time true
        end
      end

      def osl_opensearch_client
        osl_install_opensearch_gem unless gem_installed?('opensearch-ruby')

        raise 'opensearch-ruby Gem Missing' unless gem_installed?('opensearch-ruby')

        require 'opensearch-ruby' unless defined?(::OpenSearch)

        s = osl_opensearch_secrets
        params = {
          hosts: s['hosts'],
          transport_options: {
            ssl: {
              client_cert: OpenSSL::X509::Certificate.new(File.read('/etc/opensearch/easy-rsa/pki/issued/admin.crt')),
              client_key: OpenSSL::PKey::RSA.new(File.read('/etc/opensearch/easy-rsa/pki/private/admin.key')),
              ca_file: '/etc/opensearch/easy-rsa/pki/ca.crt',
            },
          },
        }

        @opensearch_client ||= OpenSearch::Client.new(params)
      end

      def osl_opensearch_username(user)
        begin
          osl_opensearch_client.security.get_user(username: user)
        rescue OpenSearch::Transport::Transport::Errors::NotFound
          false
        end
      end

      private

      def gem_installed?(gem_name)
        !Gem::Specification.find_by_name(gem_name).nil?
      rescue Gem::LoadError
        false
      end
    end
  end
end
Chef::DSL::Recipe.include ::OslOpensearch::Cookbook::Helpers
Chef::Resource.include ::OslOpensearch::Cookbook::Helpers

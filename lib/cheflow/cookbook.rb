module Cheflow
  class Cookbook

    attr_reader :berksfile


    def initialize(options)
      @options = options
      @berksfile = Berkshelf::Berksfile.from_options(options.dup)
    end

    def metadata
      @metadata ||= begin
        metadata_path = File.expand_path(File.join(path, 'metadata.rb'))
        Ridley::Chef::Cookbook::Metadata.from_file(metadata_path)
      end
    end

    def version
      @version ||= Semverse::Version.new(metadata.version)
    end

    def name
      @name ||= metadata.name
    end

    def path
      @path ||= File.dirname(berksfile.filepath)
    end

    def type
      @type ||= if name.start_with? 'node_'
        :node
      else
        :non_node
      end
    end

    def node_cookbook?
      type == :node
    end

    def node_environment_objects
      @node_environment_objects ||= begin
        if node_cookbook?
          ridley.search(:environment, "name:#{name}*")
        else
          ridley.search(:environment, "cookbook_versions:#{name}")
        end
      end
    end

    def node_environments
      @node_environments ||= node_environment_objects.map do |e|
        env = e.name.gsub /^#{name}_/, ''
        env = env == name ? 'production' : env
        "#{env.ljust(12)} (#{e.cookbook_versions[name]})" if e.cookbook_versions[name]
      end.compact.sort
    end

    def versions
      @versions ||= ridley.cookbook.versions(name)
    end

    def dev_versions
      versions.select { |v| Semverse::Version.new(v).patch.odd? }
    end

    def prod_versions
      versions.select { |v| Semverse::Version.new(v).patch.even? }
    end

    def to_s
      "#{name} v#{version}#{' (dev)' if version.patch.odd?}#{' (FROZEN)' if frozen?}"
    end

    def frozen?
      ridley.cookbook.find(name, version).frozen?
    end

    def upload
      ridley.cookbook.upload path, freeze: !version.patch.odd?
    end


    private

      def ridley
        @ridley ||= Ridley.new(server_url: config.chef.chef_server_url, client_name: config.chef.node_name,
          client_key: config.chef.client_key, ssh: {
            user: @options[:ssh_user], password: @options[:ssh_password], keys: @options[:ssh_key],
            sudo: use_sudo?
        }, ssl: {
          verify: config.ssl.verify
        })
      end

      def config
        Berkshelf::Config.instance
      end

      def use_sudo?
        @options[:sudo].nil? ? true : @options[:sudo]
      end

  end
end

require 'cheflow'
require 'thor'
require 'semverse'
require 'tempfile'
require 'fileutils'
require 'celluloid'

module Cheflow
  class Cli < Thor

    LATEST = "latest".freeze


    def initialize(*args)
      super(*args)

      Ridley.logger.level = ::Logger::INFO if @options[:verbose]
      Ridley.logger.level = ::Logger::DEBUG if @options[:debug]
    end


    namespace 'cheflow'

    map 'up' => :upload
    map 'ud' => :update
    map 'a' => :apply
    map 'o' => :outdated
    map 'i' => :info
    map 'b' => :bump
    map ["ver", "-v", "--version"] => :version

    class_option :berksfile,
      type: :string,
      default: nil,
      desc: 'Path to a Berksfile to operate off of.',
      aliases: '-b',
      banner: 'PATH'
    class_option :ssh_user,
      type: :string,
      desc: "SSH user to execute commands as",
      aliases: "-u",
      default: ENV["USER"]
    class_option :ssh_password,
      type: :string,
      desc: "Perform SSH authentication with the given password",
      aliases: "-p",
      default: nil
    class_option :ssh_key,
      type: :string,
      desc: "Perform SSH authentication with the given key",
      aliases: "-P",
      default: nil

    desc 'upload', 'Upload the current cookbook'
    long_desc <<-LONGDESC
      Upload the current cookbook - the current cookbook being that which is in the current working
      directory. The current version of the cookbook will determine if this upload should be frozen
      or not. If it is a dev version (ie. a patch release), then the uploaded cookbook is not
      frozen.
    LONGDESC
    def upload
      say "Uploading #{cookbook.type} Cookbook: #{cookbook}"
      begin
        cookbook.upload
      rescue Ridley::Errors::FrozenCookbook => e
        say e, :red
        exit(1)
      end
    end

    desc 'update [COOKBOOKS]', 'Update the cookbooks (and dependencies) specified in the Berksfile'
    def update(*cookbook_names)
      cookbook.berksfile.update *cookbook_names
    end

    desc 'outdated [COOKBOOKS]', 'List dependencies that have new versions available that satisfy their constraints'
    def outdated(*names)
      outdated = cookbook.berksfile.outdated(*names)
      Berkshelf.formatter.outdated(outdated)
    end

    desc 'apply ENVIRONMENT', 'Apply version locks from Berksfile.lock to a Chef environment'
    def apply(environment_name)
      unless cookbook.node_cookbook?
        say "Cannot apply Non-Node Cookbooks. Run this again for a Node Cookbook", :red
        exit(1)
      end

      lockfile = File.join(cookbook.path, Berkshelf::Lockfile::DEFAULT_FILENAME)
      unless File.exist?(lockfile)
        say "No lockfile found at #{lockfile}", :red
        exit(1)
      end

      full_environment_name = "node_#{cookbook.node_name}"
      full_environment_name += "_#{environment_name}" if environment_name != 'production'

      say "Applying Node Cookbook #{cookbook} and its dependencies to #{environment_name} (#{full_environment_name})", :bold

      if environment_name == 'production'
        exit(1) unless yes?('Are you sure you wish to apply locked versions to production?', :red)
      end

      lockfile = Berkshelf::Lockfile.from_file(lockfile)
      begin
        unless lockfile.apply(full_environment_name)
          error "Failed to apply locked versions"
          exit(1)
        end
      rescue Berkshelf::EnvironmentNotFound => e
        say "Unable to apply locked versions. #{e}", :red
        exit(1)
      end
    end

    desc 'version', 'Display version information'
    def version
      say "Cheflow v#{Cheflow::VERSION}"
    end

    desc 'bump', 'Bump the version, which is by default the patch version.'
    long_desc <<-LONGDESC
      Pass in the Semver level as the first argument to specify which level to bump.
      Available levels are `major`, `minor` or `patch`.

      Bump the patch version:
      \x5> $ cheflow bump

      Bump the major version:
      \x5> $ cheflow bump major
    LONGDESC
    def bump(level='patch')
      from = cookbook.version
      major, minor, patch = from.major, from.minor, from.patch
      binding.eval("#{level} = #{from.send(level)+1}")
      to = "#{major}.#{minor}.#{patch}"

      version_file = File.join(cookbook.path, 'VERSION')
      if File.exist? version_file
        File.open(version_file, 'w') { |file| file.puts to }
        say "Bumped #{level} version from #{from} to #{to}", :green
      else
        say "The 'VERSION' file does not exist, so cannot bump the #{level} version", :red
        exit(1)
      end
    end

    desc 'info', 'Display information about the cookbook'
    def info
      say "#{cookbook.type.capitalize} Cookbook: #{cookbook}", :bold
      say cookbook.path
      say
      say "Environments: #{cookbook.node_environments(true).join("\n              ")}"

      pv = cookbook.prod_versions
      dv = cookbook.dev_versions

      if dv.count > 0 || pv.count > 0
        say
        say 'Versions: (most recent)'

        if pv.count > 0
          if pv.count > 10
            say "  Production:  #{pv[0,10].join(', ')} (...)"
          else
            say "  Production:  #{pv.join(', ')}"
          end
        end

        if dv.count > 0
          if dv.count > 10
            say "  Development:  #{dv[0,10].join(', ')} (...)"
          else
            say "  Development:  #{dv.join(', ')}"
          end
        end

        say
      end
    end

    desc 'default', 'Show version, info and help'
    def default
      invoke :version
      say
      say '-' * 90
      invoke :info
      say '-' * 90
      say
      invoke :help
    end
    default_task :default


    private

      def cookbook
        @cookbook ||= Cheflow::Cookbook.new(options)
      end

  end
end

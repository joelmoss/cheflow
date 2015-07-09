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

    map 'up' => :upgrade
    map 'i' => :info
    map 'b' => :bump
    map ["ver", "-v", "--version"] => :version

    class_option :verbose,
      type: :boolean,
      desc: "Output verbose information",
      aliases: "-v",
      default: false
    class_option :debug,
      type: :boolean,
      desc: "Output debug information",
      aliases: "-d",
      default: false
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

    # desc "upgrade [environment]", "Upload and apply the current cookbook version to the specified"
    # def upgrade(env = 'development')
    # end

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
      end
    end

    desc 'info', 'Display information about the cookbook'
    def info
      say "#{cookbook.type.capitalize} Cookbook: #{cookbook}"
      say cookbook.path
      say
      say "Environments: #{cookbook.node_environments.join("\n              ")}"
      say

      say 'Versions: (most recent)'

      if (pv = cookbook.prod_versions).count > 15
        say "  Production:  #{pv[0,15].join(', ')} (...)"
      else
        say "  Production:  #{pv.join(', ')}"
      end

      if (dv = cookbook.dev_versions).count > 15
        say "  Development:  #{dv[0,15].join(', ')} (...)"
      else
        say "  Development:  #{dv.join(', ')}"
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

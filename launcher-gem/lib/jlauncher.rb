require "jlauncher/version"
require 'zip'
require 'json'
require 'jlauncher/repos'
require 'jlauncher/common.rb'
require 'optimist'
require 'fileutils'
require 'colorize'

module JLauncher

  def JLauncher.do_it(argv)
    parser = Optimist::Parser.new
    parser.stop_on_unknown
    parser.stop_on %w(run install)
    parser.version VERSION
    parser.banner <<-EOS
Starts a jar with a j-manifest.json description fetching (and caching) all dependencies.

Usage:
.. j [options] <run|install> <jarfile|manifestfile|mavencoordinates> args...
where [options] are:
    EOS
    parser.opt :verbose, "Print debugging info to stderr"

    begin
      opts = parser.parse(argv)
    rescue Optimist::CommandlineError => e
      parser.die(e.message, nil, e.error_code)
    rescue Optimist::HelpNeeded
      parser.educate
      exit
    rescue Optimist::VersionNeeded
      puts parser.version
      exit
    end

    verbose = opts[:verbose]

    remaining_args = parser.leftovers

    subcommand = remaining_args.shift


    resolver = Resolver.new(
        MavenRepo.new(File.join(Dir.home, ".m2", "repository")),
        IvyRepo.new(File.join(Dir.home, ".ivy2")),
        MavenRemote.new("https://repo1.maven.org/maven2"),
        verbose
    )


    if subcommand == "run"
      start_coordinates = remaining_args.shift

      full_config = resolve_full_config(resolver, start_coordinates, verbose)

      program_args = remaining_args[0..-1]

      launch_config = full_config.launch_config(resolver)

      launch_config.run(program_args)
    else
      if subcommand == "install"
        subcommand_parser = Optimist::Parser.new
        subcommand_parser.opt :executable_name, "Name of the executable script.", :type => :string

        begin
          opts = subcommand_parser.parse(remaining_args)
        rescue Optimist::HelpNeeded
          subcommand_parser.educate
          exit
        end

        start_coordinates = subcommand_parser.leftovers.first

        full_config = resolve_full_config(resolver, start_coordinates, verbose)

        executable_name = full_config.manifest.executable_name || opts[:executable_name]

        if !executable_name
          raise "Manifest does not contain executable name, please specify one on the commandline like so:\n" +
                    "jlauncher install --executable-name myexecutablename #{full_config.start_coordinates}"
        end

        bin_dir = File.expand_path("~/.config/jlauncher/bin")

        executable_path = bin_dir + "/" + (executable_name)
        FileUtils.mkdir_p(bin_dir)
        File.write(executable_path, <<~HEREDOC
          #!/usr/bin/env bash        

          set -e
          set -u
          set -o pipefail

          jlauncher run #{full_config.start_coordinates} "$@"
        HEREDOC
        )

        File.chmod(0755, executable_path)
        check_path(bin_dir)

        STDERR.puts("'#{full_config.start_coordinates}' has been installed as #{executable_name.bold}.")
      else
        raise "'#{subcommand}' is not a valid subcommand."
      end
    end
  end

  def self.check_path(bin_dir)
    path_entries = ENV['PATH'].split(":").map { |path| File.expand_path(path) }
    if (!path_entries.include?(bin_dir))
      STDERR.puts("Warning: The jlauncher binary path is not on the system path. You can add it to your .bashrc like so:".yellow)
      STDERR.puts("export PATH=$PATH:#{bin_dir}\n\n")
    end
  end

  def self.read_manifest(jarfile)
    Zip::File.open(jarfile) do |zip_file|
      entry = zip_file.glob('j-manifest.json').first
      Manifest.new(JSON.parse(entry.get_input_stream.read))
    end
  end


  # All the info that is needed to launch
  class JvmLaunchConfig
    def initialize(classpath_elements, main_class)

      @main_class = main_class
      @classpath_elements = classpath_elements
    end

    def run(args)
      classpath = @classpath_elements.join(File::PATH_SEPARATOR)
      exec("java", "-cp", "#{classpath}", "#{@main_class}", *args)
    end
  end


  # The full configuration needed to start a program has a manifest
  # plus an optional extra_class_path element, which contains either
  # maven coordinates or a local file containing a jar
  class FullConfig
    attr_reader :manifest, :start_coordinates

    def initialize(manifest, extra_class_path, start_coordinates)
      @manifest = manifest
      @extra_class_path = extra_class_path
      @start_coordinates = start_coordinates

    end


    def launch_config(resolver)
      class_path_from_manifest = @manifest.dependencies.map {
          |c| resolver.get(c)
      }

      if @extra_class_path
        split_index = @extra_class_path.index(":")
        protocol = @extra_class_path[0..split_index - 1]
        value = @extra_class_path[split_index + 1..-1]
        extra_element = case protocol
                        when "file"
                          value
                        when "maven"
                          resolver.get(Coordinates.new(value))
                        end
        class_path_from_manifest = class_path_from_manifest << extra_element
      end

      JvmLaunchConfig.new(
          class_path_from_manifest,
          @manifest.main_class
      )
    end
  end


  # A wrapper around the manifest file
  class Manifest
    def initialize(json_map)
      @json_map = json_map
    end

    def dependencies
      @json_map['dependencies'].map { |dep| Coordinates.new(dep) }
    end

    def main_class
      @json_map['mainClass']
    end

    def executable_name
      @json_map['executableName']
    end
  end

  private

  def self.resolve_full_config(resolver, start_coordinates, verbose)
    full_config = if File.exist?(start_coordinates)
                    if (start_coordinates.end_with?(".jar"))
                      STDERR.puts("Starting local jar") if verbose

                      start_coordinates = File.expand_path(start_coordinates)

                      extra_class_path = "file:" + File.expand_path(start_coordinates)


                      manifest = read_manifest(start_coordinates)
                      FullConfig.new(manifest, extra_class_path, start_coordinates)
                    else
                      STDERR.puts("Starting local manifest") if verbose

                      manifest = Manifest.new(JSON.parse(File.read(start_coordinates)))

                      extra_class_path = nil
                      FullConfig.new(manifest, extra_class_path, start_coordinates)
                    end
                  else
                    STDERR.puts("Starting from repo jar") if verbose

                    components = start_coordinates.split(":")
                    if components.length != 3
                      raise "'#{start_coordinates}' is not a valid coordinate use <groupId>:<artifactId>:<version>"
                    end

                    main_jar = resolver.get(Coordinates.new(start_coordinates))

                    manifest = read_manifest(main_jar)
                    extra_class_path = "maven:" + start_coordinates
                    FullConfig.new(manifest, extra_class_path, start_coordinates)
                  end
    full_config
  end
end

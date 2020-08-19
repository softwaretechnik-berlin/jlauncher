require "j/version"
require 'zip'
require 'json'
require 'j/repos'
require 'j/common.rb'
require 'optimist'

module JLauncher

    def JLauncher.do_it(argv)
        parser = Optimist::Parser.new
        parser.stop_on_unknown
        parser.version VERSION
        parser.banner <<-EOS
Starts a jar with a j-manifest.json description fetching (and caching) all dependencies.

Usage:
.. j [options] <jarfile|manifestfile|mavencoordinates> args...
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
        start_param = remaining_args[0]
        program_args = remaining_args[1..-1]

        resolver = Resolver.new(
            MavenRepo.new(File.join(Dir.home, ".m2", "repository")),
            IvyRepo.new(File.join(Dir.home, ".ivy2")),
            MavenRemote.new("https://repo1.maven.org/maven2"),
            verbose
        )

        start_info = if File.file?(start_param)
                       if (start_param.end_with?(".jar"))
                        STDERR.puts("Starting local jar") if verbose

                        manifest = read_manifest(start_param)

                        StartInfo.new(manifest.dependencies.map {|c| resolver.get(c)} << start_param, manifest.main_class)
                       else
                         STDERR.puts("Starting local manifest") if verbose

                         manifest = Manifest.new(JSON.parse(File.read(start_param)))

                         StartInfo.new(manifest.dependencies.map {|c| resolver.get(c)} << start_param, manifest.main_class)
                       end
                     else
                         STDERR.puts("Starting from repo jar") if verbose

                         components = start_param.split(":")
                         if components.length != 3
                             raise "'#{start_param}' is not a valid coordinate use <groupId>:<artifactId>:<version>"
                         end

                         main_jar = resolver.get(Coordinates.new({
                             'groupId' => components[0],
                             'artifactId' => components[1],
                             'version' => components[2]
                         }))

                         manifest = read_manifest(main_jar)

                         StartInfo.new(manifest.dependencies.map {|c| resolver.get(c)} << main_jar, manifest.main_class)
                    end

        start_info.run(program_args)
        
        classpath = classpath_elements.join(File::PATH_SEPARATOR)
        exec("java", "-cp", "#{classpath}", "#{manifest.main_class}")
    end

    def self.read_manifest(jarfile)
        Zip::File.open(jarfile) do |zip_file|
            entry = zip_file.glob('j-manifest.json').first 
            Manifest.new(JSON.parse(entry.get_input_stream.read))
        end
    end


    # All the info that is needed to launch
    class StartInfo
        def initialize(classpath_elements, main_class)

            @main_class = main_class
            @classpath_elements = classpath_elements
        end

        def run(args)
            classpath = @classpath_elements.join(File::PATH_SEPARATOR)
            exec("java", "-cp", "#{classpath}", "#{@main_class}",  *args)
        end

    end

    
    # A wrapper around the manifest file
    class Manifest
        def initialize(json_map)
            @json_map = json_map
        end

        def dependencies
            @json_map['dependencies'].map {|dep| Coordinates.new(dep)}
        end

        def main_class
            @json_map['mainClass']
        end
    end

end

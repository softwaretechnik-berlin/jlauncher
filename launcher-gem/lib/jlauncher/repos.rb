require 'httparty'

class Resolver
    def initialize(local_maven_repo, local_ivy_repo, remote, verbose)

        @local_maven_repo = local_maven_repo
        @local_ivy_repo = local_ivy_repo
        @remote = remote
        @verbose = verbose
    end

    def get(coordinates)
        path = @local_maven_repo.local_path(coordinates)

        if File.exists?(path)
            STDERR.puts("'#{coordinates}' found in local maven repo at #{path}") if @verbose
            return path
        end

        path = @local_ivy_repo.local_path(coordinates)
        if File.exists?(path)
            STDERR.puts("'#{coordinates}' found in local ivy repo at #{path}") if @verbose
            return path
        end

        path = @local_ivy_repo.cache_path(coordinates)
        if File.exists?(path)
            STDERR.puts("'#{coordinates}' found in ivy cache at #{path}") if @verbose
            return path
        end
        
        STDERR.puts "'#{coordinates} not found in cache, trying to get them from remote..." if @verbose

        FileUtils.makedirs(File.dirname(path))
        content = @remote.get(coordinates)

        open(path, "wb") do |file|
            file.write(content)
        end
        path
    end

end

class MavenRepo
    def initialize(path)
        @path = path
    end

    # for now we only support going for jars, thus no type or classifier or even platform here
    # (to be honest mostly the latter may be interesting for us)
    def local_path(coordinates)
        File.join(@path, coordinates.local_maven_path)
    end
end

class IvyRepo
    def initialize(path)
        @path = path
    end

    # for now we only support going for jars, thus no type or classifier or even platform here
    # (to be honest mostly the latter may be interesting for us)
    def local_path(coordinates)
        File.join(@path,"local", coordinates.local_ivy_path)
    end

    # for now we only support going for jars, thus no type or classifier or even platform here
    # (to be honest mostly the latter may be interesting for us)
    def cache_path(coordinates)
        File.join(@path, "cache", coordinates.local_ivy_path)
    end

end


class MavenRemote
    def initialize(url)
        @url = url
    end

    def get(coordinates)
        uri = URI(@url + "/" + coordinates.relative_url)

        response = HTTParty.get(uri)

        if response.code != 200
            raise "Error getting #{uri} response code #{response.code}"
        end

        response.body
    end
end
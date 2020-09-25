class Coordinates

    def initialize(coords)
        if coords.is_a? Hash
            @group_id = coords['groupId']
            @artifact_id = coords['artifactId']
            @version = coords['version']
            return
        end
        if coords.is_a? String
           components = coords.split(":")
           @group_id = components[0]
           @artifact_id = components[1]
           @version = components[2]
           return
        end

        raise "Could not parse coordinates " + coords.to_s


    end

    def to_s
        @group_id + ":" + @artifact_id + ":" + @version
    end
    
    def local_maven_path
        File.join(@group_id.split("."), @artifact_id, @version, @artifact_id + "-" + @version + ".jar")
    end

    def local_ivy_path
        File.join(@group_id, @artifact_id, "jars", @artifact_id + "-" + @version + ".jar")
    end

    def relative_url
        @group_id.split(".").join("/") + "/" + @artifact_id + "/" + @version + "/"  + @artifact_id + "-" + @version + ".jar"

    end
end
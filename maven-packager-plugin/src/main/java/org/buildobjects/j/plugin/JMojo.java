package org.buildobjects.j.plugin;

import com.googlecode.totallylazy.Sequence;
import org.apache.commons.io.FileUtils;
import org.apache.maven.artifact.Artifact;
import org.apache.maven.artifact.repository.ArtifactRepository;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.plugins.annotations.ResolutionScope;
import  org.apache.maven.project.MavenProject;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONString;

import java.io.File;
import java.io.IOException;

import static com.googlecode.totallylazy.Sequences.sequence;

@Mojo(
    name = "j",
    requiresDependencyResolution = ResolutionScope.RUNTIME,
    threadSafe = true)
public class JMojo extends AbstractMojo {

	@Parameter(property = "j.mainClass")
	private String mainClass;

	@Parameter(property = "j.executableName")
	private String executableName;

	@Parameter(property = "j.targetJvm")
	private String targetJvm;

	@Parameter(property = "j.outputDirectory", defaultValue = "${project.build.directory}/classes")
	private String outputDirectory;

	@Parameter(defaultValue = "${project}", readonly = true, required = true)
	protected MavenProject mavenProject;

	/**
	 * Execute j.
	 *
	 */
	@Override
	public void execute() throws MojoExecutionException {
		getLog().info("Running the j manifest generation");

        try {
            if (mainClass == null) {
                throw new RuntimeException("No main class specified");
            }

            Sequence<Artifact> deps = sequence(mavenProject.getArtifacts());

			Sequence<ArtifactRepository> repos = sequence(mavenProject.getRemoteArtifactRepositories());

			JSONArray dependencies = new JSONArray(deps.map(artifact ->
					new JSONObject()
						.put("groupId", artifact.getGroupId())
						.put("artifactId", artifact.getArtifactId())
						.put("version", artifact.getVersion())
						.put("size", artifact.getFile().length())

			));
            //TODO Think about the scope artifact.getScope()

			JSONObject metadata = new JSONObject()
                .put("mainClass", getMainClass())
				.put("dependencies", dependencies)
				.put("repositories", new JSONArray(repos.map(r -> r.getUrl())));

			if (executableName != null) {
				metadata.put("executableName", executableName);
			}

			if (targetJvm != null) {
				metadata.put("targetJvm", targetJvm);
			}

			FileUtils.forceMkdir(new File(outputDirectory));
			FileUtils.write(new File(new File(outputDirectory),"j-manifest.json"), metadata.toString(4));
        } catch (IOException e) {
            throw new RuntimeException("Problems generating j-manifest.", e);
        }

	}

    public String getMainClass() {
        return mainClass;
    }

    public String getOutputDirectory() {
        return outputDirectory;
    }
}

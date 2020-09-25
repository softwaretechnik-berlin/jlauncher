# Introduction

jlauncher is a utility that makes it easy to run jvm based programs without having to assemble them
into "fat jars". jlauncher fetches jar files and their dependencies from maven style repos and launches a main class.

The input is a special manifest that locks down all dependency versions, so that the launch is repeatable.

# Installing jlauncher

Currently jlauncher is implemented in ruby and distributed as a ruby gem. The installation is straightforward:

```bash
gem install jlauncher
```

# Launching a Local Manifest File

Here is an example of a manifest file to launch a [helloworld example](maven-example/src/main/java/org/programmiersportgruppe/jtester/App.java)
directly from maven central:

```json
{
  "mainClass": "org.programmiersportgruppe.jtester.App",
  "dependencies": [
    {
      "groupId": "com.beust",
      "artifactId": "jcommander",
      "version": "1.72"
    },
    {
      "groupId": "org.programmiersportgruppe",
      "artifactId": "j-maven-tester",
      "version": "0.2.0"
    }
  ]
}
```

The `jlauncher` command line tool can now be used to launch the manifest. The parameters after the manifest are
passed into the main class.

```bash
jlauncher run manifest.json --name Tom
```

While manifest can be created manually,
this process can be automated using the maven / sbt plugin. Also,
the convention is to package a manifest as `j-manifest.json` into an 
"executable" jar.

# Launching from a Local Jar-File

A jar file containing a j-manifest can then be launched like this:

```bash
jlauncher run target/j-maven-tester-0.2.0.jar --name Jerry
```

# Launching from Maven Coordinates

If the jar is deployed to maven central we can also launch it using its maven coordinates:

```bash
jlauncher run org.programmiersportgruppe:j-maven-tester:0.2.0 --name World
```

# Installing a Wrapper Script

jlauncher also supports the installation of a wrapper script,
in the jlauncher `bin`-directory, so that a utiltiy packaged
with jlauncher manifest can be started with a simple script name.

If we take our previous hello world example, we can install it 
like so:

```bash
jlauncher install org.programmiersportgruppe:j-maven-tester:0.2.0
```
 
With the jlauncher `bin`-directory on the path we can now start
hello world like this:

```bash
hello-world --name Donald
```

# Creating an executable jar with Maven

To get started you need to add the plugin to your maven build and specify the main class:

```xml
 <build>
        <plugins>

            <plugin>
                <groupId>org.buildobjects</groupId>
                <artifactId>j-maven-plugin</artifactId>
                <version>0.2.0</version>
                <executions>
                    <execution>
                        <phase>generate-resources</phase>
                        <goals>
                            <goal>j</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <mainClass>org.programmiersportgruppe.App</mainClass>
                    <executableName>hello-world</executableName>
                </configuration>
            </plugin>
        </plugins>
    </build>
```

# Creating an Executable Jar with SBT

Include the plugin into your project/plugins.sbt

```scala
addSbtPlugin("org.programmiersportgruppe.sbt" % "jpackager" % "0.2")
```

Then add the following to your main module:

```scala
mainClass := Some("org.programmiersportgruppe.App")

resourceGenerators in Compile += generateManifest
```

# Creating an Executable Jar with mill

Mill currently doesn't have a plugin concept, so here we provide a snippet to generate a manifest (and package it
into the jar):

```scala
object mymodule extends SbtModule {

  // … Normal module definition stuff left out for clarity

  // Include the manifest in the classpath so that it gets packaged:
  override def localClasspath = T {super.localClasspath() ++ jManifest()}

  // The task to create the manifest:
  def jManifest: Target[Seq[PathRef]] = T {
    os.makeDir.all(T.dest)
    val (_, resolution) = Lib.resolveDependenciesMetadata(
      repositories,
      resolveCoursierDependency().apply(_),
      transitiveIvyDeps(),
      Some(mapDependencies())
    )

    val jsonManifest = ujson.write(
      ujson.Obj(
        "mainClass" -> ujson.Str(mainClass().get),
        "executableName" -> ujson.Str("hello-world"),
        "dependencies" ->
          resolution.dependencies.map(x =>
            ujson.Obj(
              "groupId" -> ujson.Str(x.module.organization.value),
              "artifactId" -> ujson.Str(x.module.name.value),
              "version" -> ujson.Str(x.version)
            )
        )), indent = 4)

    os.write(T.dest / "j-manifest.json", jsonManifest)

    Seq(PathRef(T.dest))
  }
}
```

## Backlog

- [x] Fix typo in SBT key.
- [ ] Make repositories overridable/ allow to define bootstrap,
      repository, perhaps in a global config.
- [ ] Add field for repositories in `manifest`, so that
      artifacts can be pulled in from arbitrary repos.
- [ ] Allow to specify vm version in the manifest.

  It would be nice to allow to specify version ranges, e.g. >= 9

  The launcher should be able to pick the right jvm if it can find
  it following platform conventions, e.g. doing a `/usr/libexec/java_home -X` on macOS.

- [ ] Allow to specify vm options in the manifest.
- [ ] Make vm options overridable on the command line.
- [X] Have a way to add aliases/ wrapper scripts so that we can create an alias for a tool.
      => We can now install.
- [ ] Reimplement jlauncher in go, so that we can have a small statically linked executable that is
      more suitable for use in a docker container.
- [ ] Add progress bar for fetching deps
- [ ] Make verbose mode beautiful, alignment, colours
- [ ] Add optional size to dependencies in manifest, so that we have more accurate progress info.
- [ ] Support "LATEST" version when using maven coordinates (this should also work offline)
- [ ] Bash completion (local or remote, caching) for maven coordinates.

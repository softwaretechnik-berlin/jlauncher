# jlauncher

jlauncher fetches (executable) jar files and their dependencies from maven style repos and launches them.
It uses a special manifest that locks down all dependency versions, so that the launch is repeatable.

Here is an example manifest file:

~~~json
{
    "mainClass": "org.programmiersportgruppe.jtester.App",
    "dependencies": [{
        "groupId": "com.beust",
        "artifactId": "jcommander",
        "version": "1.72"
    },{
        "groupId": "org.programmiersportgruppe",
        "artifactId": "j-maven-tester",
        "version": "1"
    }]
}
~~~

jlauncher can be used to launch this configuration:

~~~
j manifest.json --name Tom
~~~

There are Maven and SBT plugins to produce jars with a j-manifest.json file.

## Launching a jar from a repo

Launching a jar is done with the `j` utility, which is distributed as a ruby gem. The installation
is done like this:

    $ gem install jlauncher

Then you can launch a jar using its maven coordinates:

    $ j org.programmiersportgruppe:j-maven-tester:1 --name World

Instead of the maven coordiantes you can also use the local path of a jar file:


    $ j target/j-maven-tester-1.jar




## Creating an executable jar with Maven




To get started you need to add the plugin to your maven build and specify the main class:

~~~ .xml

 <build>
        <plugins>

            <plugin>
                <groupId>org.buildobjects</groupId>
                <artifactId>j-maven-plugin</artifactId>
                <version>0.1</version>
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
                </configuration>
            </plugin>
        </plugins>
    </build>
~~~



# Creating an Executable Jar with SBT

Include the plugin into your project/plugins.sbt

~~~
addSbtPlugin("org.programmiersportgruppe.sbt" % "jpackager" % "0.2")
~~~

Then add the following to your main module:

~~~
mainClass := Some("Main")

resourceGenerators in Compile += generateManifest
~~~


## TODO

* [X] Fix typo in SBT key
* [ ] Rename manifest file to be unique
* [ ] Add field for repositories in `manifest`, so that
      artifacts can be pulled in from arbitrary repos.
* [ ] Make verbose mode beautiful, alignment, colours
* [ ] Add progress bar for fetching deps
* [ ] Add size to dependencies (for better progress info)
* [ ] Add vm version option
* [ ] Add vm options to `manifest`
* [ ] Make vm options overridable on the command line
* [ ] Make repositories overridable/ allow to define bootstrap,
      repository, perhaps in a global config
* [ ] Support "LATEST" version this should also work offline
* [ ] Alias creation support
* [ ] Bash completion (local or remote, caching)

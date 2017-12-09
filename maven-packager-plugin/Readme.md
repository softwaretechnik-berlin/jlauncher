# J Maven Plugin


This plugin generates a j-manifest.json file for your project, so that the application
can be started anywhere with the [`j`](https://github.com/programmiersportgruppe/j) utility.

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



package org.programmiersportgruppe.jtester;

import com.beust.jcommander.JCommander;

import static java.lang.System.exit;

public class App {

    public App(ParsedArgs parsedArgs) {
        System.out.println("Hello " + parsedArgs.name + "!");
    }

    public static void main(String[] args) {
        ParsedArgs parsedArgs = new ParsedArgs();
        JCommander jc = JCommander.newBuilder()
            .addObject(parsedArgs)
            .build();

        jc.setProgramName("j-tester");

        try {
            jc.parse(args);
        } catch (com.beust.jcommander.ParameterException ex) {
            System.out.println();
            System.out.println(ex.getMessage());
            System.out.println();
            jc.usage();
            exit(1);
        }
        if (parsedArgs.help) {
            jc.usage();
            exit(0);
        }

        new App(parsedArgs);
    }
}

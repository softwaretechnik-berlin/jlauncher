package org.programmiersportgruppe.jtester;

import com.beust.jcommander.Parameter;

/**
 * This class
 */
public class ParsedArgs {
    @Parameter(names = "--name", description = "The name of the person to be greeted.", required = true)
    String name;

    @Parameter(names = "--help", help = true)
    boolean help;
}

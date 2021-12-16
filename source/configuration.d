module configuration;

import std.stdio : File, stdout, stderr;
import subcommand;

void parseArguments(string[] args)
{
    import std.string : empty;

    if (args.empty)
    {
        stderr.writeln("No subcommand specified");
        printHelpAndExit(1, stderr);
    }
    else if (args[0]!in subcommands)
    {
        stderr.writeln("Subcommand '" ~ args[0] ~ "' not recognized");
        printHelpAndExit(1, stderr);
    }
    else
    {
        SubCommand subcommand = subcommands[args[0]];
        subcommand.parseOptions(args[1 .. $]);
        subcommand.run();
    }
}

private void printHelpAndExit(uint exitStatus = 0, File sink = stdout)
{
    import subcommand;
    import core.stdc.stdlib : exit;

    string usageInfo = "Usage: degast <subcommand> [subcommand-options]";
    string subcommandsInfo = "Subcommands:\n" ~ getSubCommandHelpMessage();
    sink.writeln(usageInfo ~ "\n" ~ subcommandsInfo);
    exit(exitStatus);
}

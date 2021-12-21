module configuration;

import std.stdio : File, stdout, stderr;
import subcommand;

void parseArguments(string[] args)
{
    if (args.length == 0)
    {
        stderr.writeln("No subcommand specified");
        printHelpAndExit(1, stderr);
    }
    else
    {
        runCommandBySmallestUniquePrefix(args[0], args[1 .. $]);
    }
}

private void runCommandBySmallestUniquePrefix(string subcommandPrefix, string[] subcommandArgs)
{
    import std.algorithm.searching : startsWith;
    import std.algorithm.iteration : filter;
    import std.array : array;

    string[] prefixedCommands = subcommands.keys.filter!(s => s.startsWith(subcommandPrefix)).array;

    if (prefixedCommands.length <= 0) // no subcommand with prefix
    {
        stderr.writeln("No subcommand with prefix '" ~ subcommandPrefix ~ "'");
        printHelpAndExit(1, stderr);
    }
    else if (prefixedCommands.length >= 2) // More than one subcommand with the prefix
    {
        stderr.writeln("More than one subcommand with prefix '" ~ subcommandPrefix ~ "'");
        printHelpAndExit(1, stderr);
    }
    else
    {
        SubCommand subcommand = subcommands[prefixedCommands[0]];
        subcommand.parseOptions(subcommandArgs);
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

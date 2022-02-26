module configuration;

import std.stdio : File, stdout, stderr;
import asperan.cli_args.option_parser : Subcommand, CommandLineOptionParser;
import asperan.cli_args.recursive_option_parser : RecursiveOptionParserBuilder;

import subcommand.commit;
import subcommand.changelog;
import subcommand.tag;

// This array is kept to generate easily the subcommand help message.
private Subcommand[] subcommands;
private CommandLineOptionParser mainOptionParser;

static this() {
    import std.algorithm.iteration : each;

    subcommands = [
        new Commit(),
        new Changelog(), 
        new Tag(),
    ];

    RecursiveOptionParserBuilder parserBuilder =  new RecursiveOptionParserBuilder()
        .addOption("-h", "--help", "Print help message and exit", () { printHelpAndExit(); });

    subcommands.each!(s => parserBuilder.addSubcommand(s));

    mainOptionParser = parserBuilder.build();
}

void parseArguments(string[] args)
{
    auto parseResult = mainOptionParser.parse(args);
    if (parseResult.subcommand.isNull)
    {
        stderr.writeln("No recognized subcommand has been specified");
        printHelpAndExit(1, stderr);
    }
    else
    {
        parseResult.subcommand.get.run(parseResult.remainingArguments);
    }
}

private void printHelpAndExit(uint exitStatus = 0, File sink = stdout)
{
    import core.stdc.stdlib : exit;

    string usageInfo = "Usage: degast <subcommand> [subcommand-options]" ~ "\n";
    string optionsInfo = "Options:\n" ~ getOptionHelpMessage();
    string subcommandsInfo = "Subcommands:\n" ~ getSubCommandHelpMessage();
    sink.writeln(usageInfo ~ "\n" ~ optionsInfo ~ "\n" ~ subcommandsInfo);
    exit(exitStatus);
}

private string getOptionHelpMessage()
{
    import asperan.cli_args.option_parser : CommandLineOption;
    import std.algorithm.iteration : map, reduce;
    import std.algorithm.searching : maxElement;
    import std.string : leftJustify;

    CommandLineOption[] options = mainOptionParser.getOptions;
    size_t maxShortVersionLength = options.map!(o => o.shortName.length).maxElement;
    size_t maxLongVersionLength = options.map!(o => o.longName.length).maxElement;
    return options
            .map!(
                o => 
                    " " ~
                    leftJustify(o.shortName, maxShortVersionLength) ~ 
                    " " ~
                    leftJustify(o.longName, maxLongVersionLength) ~
                    " " ~
                    o.description ~
                    "\n"
            )
            .reduce!"a ~ b";
}

private string getSubCommandHelpMessage()
{
    import std.algorithm.iteration : map;
    import std.algorithm.searching : maxElement;
    import std.string : leftJustify, join;

    size_t maxCommandLength = subcommands.map!(s => s.getName.length).maxElement;
    // dfmt off
    return subcommands
            .map!(k => " - " ~ k.getName.leftJustify(maxCommandLength, ' ') ~ " => " ~ k.getDescription)
            .join("\n");
    // dfmt on
}

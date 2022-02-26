module subcommand.tag;

import asperan.cli_args.option_parser : Subcommand;
import glparser;

final class Tag : Subcommand
{
    import asperan.cli_args.option_parser : CommandLineOptionParser;
private:
    enum string description = "manage repository tags";
    CommandLineOptionParser optionParser;
    bool isNextVersionRequested;
    string prefix;

public:

    this()
    {
        super("tag", description);
        import asperan.cli_args.recursive_option_parser : RecursiveOptionParserBuilder;
        this.optionParser = new RecursiveOptionParserBuilder()
            .addOption("-n", "--next", "calculate the next version based on commits", () { this.isNextVersionRequested = true; })
            .addOption("-p", "--prefix", "add a prefix to the version", (s) { this.prefix = s; })
            .build();
        this.isNextVersionRequested = false;
        this.prefix = "";
    }

    override CommandLineOptionParser getOptionParser()
    {
        return this.optionParser;
    }

    override void run(string[] arguments)
    {
        if (arguments.length > 0)
        {
            import std.stdio : writeln;
            writeln("WARNING: some arguments are not recognized options, they will be ignored.");
        }
        string requestedTag = getRequestedTag();
        printTag(requestedTag);
    }

private:

    enum defaultZeroVersion = "0.0.0";
    enum defaultFirstVersion = "0.1.0";

    string getRequestedTag()
    {
        import std.string : empty;
        string lastTagCommand = getLastTagDynamic();
        if (lastTagCommand.empty)
        {
            return this.prefix ~ (isNextVersionRequested ? defaultFirstVersion : defaultZeroVersion);
        }
        string lastTag = getShellOutput(lastTagCommand, "Failed to retrieve the last tag.");
        if (isNextVersionRequested)
        {
            return calculateNextTag(lastTag);
        }
        else
        {
            return lastTag;
        }
    }

    void printTag(string tag)
    {
        import std.stdio : writeln;
        writeln(tag);
    }

    string calculateNextTag(string from)
    {
        import std.conv : to;
        import std.regex : regex, matchFirst;
        enum string tagPattern = r"(\d+)\.(\d+)\.(\d+)";
        enum string scopePattern = r"(\(\w+(-\w+)?\))?";
        enum string majorUpdatePattern = r"BREAKING CHANGE:";
        enum string minorUpdatePattern = r"feat(?=" ~ scopePattern ~ r":)";
        enum string patchUpdatePattern = r"fix(?=" ~ scopePattern  ~ r":)";
        immutable string gitLogCommand = "git log ^'" ~ from ~ "' HEAD --pretty='%B'";
        auto fromVersion = from.matchFirst(regex(tagPattern));
        immutable uint major = fromVersion[1].to!uint;
        immutable uint minor = fromVersion[2].to!uint;
        immutable uint patch = fromVersion[3].to!uint;
        immutable string gitLogOutput = getShellOutput(gitLogCommand, "Failed to get git log");
        if (!gitLogOutput.matchFirst(regex(majorUpdatePattern)).empty)
        {
            return fromVersion.pre ~ (major + 1).to!string ~ ".0.0" ~ "+" ~ getCurrentIsoDate();
        }
        else if (!gitLogOutput.matchFirst(regex(minorUpdatePattern)).empty)
        {
            return fromVersion.pre ~ major.to!string ~ "." ~ (minor + 1).to!string ~ ".0" ~ "+" ~ getCurrentIsoDate();
        }
        else if (!gitLogOutput.matchFirst(regex(patchUpdatePattern)).empty)
        {
            return fromVersion.pre ~ major.to!string ~ "." ~ minor.to!string ~ "." ~ (patch + 1).to!string ~ "+" ~ getCurrentIsoDate();
        }
        else
        {
            return fromVersion.pre ~ major.to!string ~ "." ~ minor.to!string ~ "." ~ patch.to!string ~ "+" ~ getCurrentIsoDate();
        }
    }

    string getCurrentIsoDate()
    {
        import std.datetime.systime : Clock, SysTime;
        import std.datetime.date : Date;
        return (cast(Date) Clock.currTime()).toISOString();
    }
}

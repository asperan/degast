module subcommand.changelog;

import subcommand.subcommand;
import glparser;

class Changelog : SubCommand
{
    import asperan.cli_args.simple_option_parser : CommandLineOptionParser;
    import std.typecons : Nullable, nullable;

private:
    CommandLineOptionParser optionParser;
    bool generateMarkdown;
    Nullable!string fileName;

public:

    this()
    {
        import asperan.cli_args.simple_option_parser : SimpleOptionParserBuilder;
        this.optionParser = new SimpleOptionParserBuilder()
            .addOption("-m", "--markdown", "Generate a Markdown changelog.", () { this.generateMarkdown = true; })
            .addOption("-o", "--output", "Print the changelog on the specified file", (fileName) { this.fileName = fileName.nullable; })
            .build();
        this.generateMarkdown = false;
        this.fileName = Nullable!string();
    }

    void parseOptions(string[] arguments)
    {
        import std.stdio : writeln;
        const string[] remainingArgs = this.optionParser.parse(arguments);
        if (remainingArgs.length > 0)
        {
            writeln("WARNING: some arguments are not recognized options, they will be ignored.");
        }
    }

    void run()
    {
        const string changelog = generateChangelog();
        printChangelog(changelog);
    }

    string getDescription()
    {
        return "Generate a changelog of changes from the last tag or a given branch";
    }

private:

    string generateChangelog()
    {
        import std.algorithm.sorting : sort;
        import std.algorithm.iteration : filter;
        import std.array : array;
        
        GitCommitSummary[] commitFromLastTag = getCommitSummaries("^$(" ~ getLastTagDynamic() ~ ") HEAD");
        // Order of types: default = list order, custom = alphabetical order
        string[] sortedTypes = defaultHeaderType ~ getCustomHeaderTypes(commitFromLastTag).sort.array;

        immutable string baseChangelogMessage = getChangelogTitle() ~ "\n";
        string changelog = baseChangelogMessage;

        foreach(string type; sortedTypes)
        {
            string typeHeader = getHeaderForType(type);
            Nullable!string typeChangelog = generateChangelogForType(type, commitFromLastTag.filter!(c => c.type == type).array);
            if (!typeChangelog.isNull)
            {
                changelog ~= typeHeader ~ "\n" ~ typeChangelog.get ~ "\n";
            }
        }
        return (changelog == baseChangelogMessage ? "No changes." : changelog);
    }

    string getChangelogTitle()
    {
        return (this.generateMarkdown ? "# " : "") ~ "Changelog";
    }

    string getHeaderForType(string type)
    {
        import std.string : capitalize;
        return (this.generateMarkdown ? "## " : " ") ~ type.capitalize;
    }

    Nullable!string generateChangelogForType(string type, GitCommitSummary[] commits)
    {
        if (commits.length == 0)
        {
            return Nullable!string();
        }
        else
        {
            import std.algorithm.sorting : sort;
            import std.algorithm.iteration : filter, map;
            import std.string : strip, empty;
            import std.array : array, join;
            string typeChangelog = "";
            // Order of scopes: alphabetical + the last is Other (no scope)
            string[] sortedScopes = getCustomScopes(commits).sort.array;
            foreach(string zcope; sortedScopes)
            {
                string scopeHeader = getHeaderForScope(zcope);
                // Order of messages: git log order
                string messages = commits.filter!(c => !c.typeScope.isNull && c.typeScope.get == zcope).map!(c => indentMessage(c.message)).join("\n");
                typeChangelog ~= scopeHeader ~ "\n" ~ messages;
            }

            string messagesWithoutScopes = commits.filter!(c => c.typeScope.isNull).map!(c => indentMessage(c.message)).join("\n");
            if (!messagesWithoutScopes.strip.empty)
            {
                typeChangelog ~= "\n" ~ getHeaderForScope("other") ~ "\n" ~ messagesWithoutScopes;
            }
            return typeChangelog.nullable;
        }
    }

    string getHeaderForScope(string zcope)
    {
        import std.string : capitalize;
        return (this.generateMarkdown ? "### " : "  ") ~ zcope.capitalize;
    }

    string indentMessage(string message)
    {
        return (this.generateMarkdown ? "" : "  " ) ~ "* " ~ message;
    }

    void printChangelog(string changelog)
    {
        import std.stdio : File, stdout;
        File outputFile;
        if (this.fileName.isNull)
        {
            outputFile = stdout;
        }
        else
        {
            outputFile = File(this.fileName.get(), "w");
        }
        outputFile.writeln(changelog);
    }
}

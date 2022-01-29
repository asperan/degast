module subcommand.commit;

import subcommand.subcommand : SubCommand;
import std.stdio : writeln, readln, writefln;

/**
 * Commit subcommand. It allows to interactively create a conventional commit message and use it to commit the staged changes.
 */
final class Commit : SubCommand
{
    import asperan.cli_args.simple_option_parser : CommandLineOptionParser;
    import std.typecons : Nullable, nullable;
    import glparser;

private:
    CommandLineOptionParser optionParser;
    bool skipConfirmation;
public:
    /**
     * Ctor.
     */
    this()
    {
        import asperan.cli_args.simple_option_parser : SimpleOptionParserBuilder;

        this.skipConfirmation = false;
        this.optionParser = new SimpleOptionParserBuilder()
            .addOption("-nc", "--no-confirm", "Skip the confirmation request and execute the commit.", () { this.skipConfirmation = true; })
            .build();
    }

    /**
     * Parse arguments with the class OptionParser.
     *
     * The remaining arguments are ignored.
     * Params:
     *  arguments = cli argument list.
     */
    void parseOptions(string[] arguments)
    {
        const string[] remainingArgs = this.optionParser.parse(arguments);
        if (remainingArgs.length > 0)
        {
            writeln("WARNING: some arguments are not recognized options, they will be ignored.");
        }
    }

    /**
     * Run the command.
     */
    void run()
    {
        string chosenType = askType();
        Nullable!string chosenScope = askScope();
        string summary = askSummary();
        string messageBody = askBody();
        string footer = askFooter();
        string commitMessage = constructCommitMessage(chosenType, chosenScope, summary, messageBody, footer);
        if (!this.skipConfirmation)
        {
            writeln("The commit message will be:");
            writeln(commitMessage);
            const bool doCommit = askConfirmation();
            if (!doCommit)
            {
                return;
            }
        }
        gitCommit(commitMessage);
    }

    string getDescription()
    {
        return "Open interactive conventional commit generator";
    }

private:
    import std.string : empty, strip;

    string askType()
    {
        import std.conv : to, ConvException;
        import std.string : isNumeric;
        import std.range : enumerate;
        import std.algorithm.iteration : each;

        string[] types = defaultHeaderType ~ getCustomHeaderTypes(getCommitSummaries);
        bool valueIsChosen = false;
        auto enumeratedTypes = types.enumerate;
        while (!valueIsChosen)
        {
            writeln("Choose a commit type by inputting the corresponding number, or create a new one with 'n' (it is seldom needed):");
            enumeratedTypes.each!((t) { writefln("%d) %s", t.index, t.value); });
            string chosenValue = readln().strip;
            if (chosenValue == "n")
            {
                writeln("New type:");
                string newType = readln().strip;
                valueIsChosen = true;
                return newType;
            }
            else
            {
                try
                {
                    string chosenType = types[chosenValue.to!size_t];
                    valueIsChosen = true;
                    return chosenType;
                }
                catch (ConvException e)
                {
                    valueIsChosen = false;
                    writeln("Invalid input: " ~ chosenValue);
                }
            }
        }
        assert(0);
    }

    Nullable!string askScope()
    {
        import std.conv : to, ConvException;
        import std.string : isNumeric;
        import std.range : enumerate;
        import std.algorithm.iteration : each;

        string[] scopes = getCustomScopes(getCommitSummaries);
        bool valueIsChosen = false;
        auto enumeratedScopes = scopes.enumerate;
        while (!valueIsChosen)
        {
            writeln("Choose a scope by inputting the corresponding number, or create a new one with 'n' (press <enter> to skip):");
            enumeratedScopes.each!((s) { writefln("%d) %s", s.index, s.value); });
            string chosenValue = readln().strip;
            if (chosenValue.length == 0)
            {
                return Nullable!string();
            }
            else if (chosenValue == "n")
            {
                writeln("New type:");
                string newScope = readln().strip;
                valueIsChosen = true;
                return newScope.nullable;
            }
            else
            {
                try
                {
                    string chosenScope = scopes[chosenValue.to!size_t];
                    valueIsChosen = true;
                    return chosenScope.nullable;
                }
                catch (ConvException e)
                {
                    valueIsChosen = false;
                    writeln("Invalid input: " ~ chosenValue);
                }
            }
        }
        assert(0);
    }

    string askSummary()
    {
        string summary;
        do
        {
            writeln(
                    "Insert the summary message (remember: it should be short and continue the sentence 'The commit will'):");
            summary = readln().strip;
            if (summary.empty)
            {
                writeln("Summary message cannot be empty");
            }
        }
        while (summary.empty);
        return summary;
    }

    string askBody()
    {
        string messageBody = "";
        ubyte emptyLines = 0;
        string input = "";
        writeln("Insert the message body (terminate it with 2 empty lines, it can be left blank):");
        while (emptyLines < 2)
        {
            input = readln().strip;
            if (input.empty)
            {
                emptyLines += 1;
                messageBody ~= "\n";
            }
            else
            {
                emptyLines = 0;
                messageBody ~= input ~ "\n";
            }
        }
        return messageBody.strip;
    }

    string askFooter()
    {
        writeln("Insert an optional footer (usually it refers to an issue):");
        string footer = readln().strip;
        return footer;
    }

    string constructCommitMessage(string type, Nullable!string typeScope,
            string summary, string messageBody, string footer)
    {
        string header = type ~ (typeScope.isNull ? "" : "(" ~ typeScope.get ~ ")") ~ ": " ~ summary;
        // dfmt off
        return header ~ "\n"
                ~ (messageBody.empty ? "" : "\n" ~ messageBody ~ "\n")
                ~ (footer.empty ? "" : "\n" ~ footer ~ "\n");
        //dfmt on
    }

    bool askConfirmation()
    {
        import std.regex : regex, matchFirst;

        writeln("Do you confirm to proceed? (y/ye/yes/n/no) [no]");
        enum string yesPattern = r"^y(es?)?$";
        enum string noPattern = r"^no?$";
        string response;
        bool isInputWrong = true;
        while (isInputWrong)
        {
            response = readln().strip;
            if (response.empty)
            {
                isInputWrong = false;
                return false;
            }
            else
            {
                if (!response.matchFirst(regex(yesPattern)).empty)
                {
                    isInputWrong = false;
                    return true;
                }
                else if (!response.matchFirst(regex(noPattern)).empty)
                {
                    isInputWrong = false;
                    return false;
                }
                else
                {
                    writeln("Unrecognized answer, please use 'y', 'ye', 'yes' to confirm or 'n', 'no' to reject");
                    isInputWrong = true;
                }
            }
        }
        assert(0);
    }

    void gitCommit(string message)
    {
        import std.file : write, remove, FileException;
        import std.process : executeShell;
        import core.stdc.stdlib : exit;
        import std.stdio : stderr;

        enum string tempFileName = ".dgst-commit-msg";
        try
        {
            write(tempFileName, message);
            executeShell("git commit -F " ~ tempFileName);
            remove(tempFileName);
        }
        catch (FileException e)
        {
            stderr.writeln(e.msg);
            exit(1);
        }
    }
}

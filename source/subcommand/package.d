module subcommand;

public import subcommand.subcommand;
public import subcommand.commit;
public import subcommand.changelog;
import subcommand.tag;

/**
 * Map of available subcommands.
 */
SubCommand[string] subcommands;

static this()
{
    subcommands["commit"] = new Commit();
    subcommands["changelog"] = new Changelog();
    subcommands["tag"] = new Tag();
}

string getSubCommandHelpMessage()
{
    import std.algorithm.iteration : map;
    import std.algorithm.searching : maxElement;
    import std.string : leftJustify, join;

    size_t maxCommandLength = subcommands.keys.map!(k => k.length).maxElement;
    // dfmt off
    return subcommands
            .keys
            .map!(k => " - " ~ k.leftJustify(maxCommandLength, ' ') ~ " => " ~ subcommands[k].getDescription)
            .join("\n");
    // dfmt on
}

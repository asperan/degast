module subcommand;

public import subcommand.subcommand;
public import subcommand.commit;

/**
 * Map of available subcommands.
 */
SubCommand[string] subcommands;

static this()
{
    subcommands["commit"] = new Commit();
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

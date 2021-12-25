module glparser;

public import shell_utils;

GitCommitSummary[] getCommitSummaries(string revisionSpec = "--all")
{
    import std.string : split;
    import std.algorithm.iteration : map;
    import std.array : array;
    import std.conv : to;

    size_t numOfCommits = getShellOutput("git rev-list --count --all", "Failed to get total commit count.").to!size_t;
    if(numOfCommits == 0)
    {
        return [];
    }
    else
    {
        return getShellOutput("git log --pretty=\"%s\" " ~ revisionSpec, "Failed to get the commit summary list.")
            .split("\n")
            .map!(s => parseGitCommitLine(s))
            .array;
    }
}

// dfmt off
enum string[] defaultHeaderType = [
    "feat",
    "fix",
    "perf",
    "test",
    "refactor",
    "style",
    "docs",
    "build",
    "ci",
    "chore",
];
//dfmt on

string[] getCustomHeaderTypes(GitCommitSummary[] summaries)
{
    import std.algorithm.iteration : map, filter, fold;
    import std.array : array;
    import std.algorithm.searching : canFind;

    return summaries.map!(c => c.type) // Map to commit type
    .fold!((a, b) => a.canFind(b) ? a : a ~ b)(cast(string[])[]) // Unique values
        .filter!(t => !defaultHeaderType.canFind(t)) // Non-default values
        .array;
}

string[] getCustomScopes(GitCommitSummary[] summaries)
{
    import std.algorithm.iteration : map, filter, fold;
    import std.array : array;
    import std.algorithm.searching : canFind;

    return summaries.filter!(c => !c.typeScope.isNull) // Filter commit with non-null scope
    .map!(c => c.typeScope.get) // Map to scope
        .fold!((a, b) => a.canFind(b) ? a : a ~ b)(cast(string[])[]) // Unique values
        .array;
}

string getLastTagDynamic()
{
    import std.string : empty;
    if (getShellOutput("git rev-list --tags", "Failed to retrieve the tag list").empty)
    {
        return "";
    }
    else
    {
        return "git describe $(git rev-list --tags --max-count=1)";
    }
}

private GitCommitSummary parseGitCommitLine(string commitString)
{
    import std.regex : regex, matchFirst;
    import std.stdio : writeln;
    import std.string : strip;

    auto headerRegex = regex(r"^\w+");
    auto scopeRegex = regex(r"(?<=\()\w+(-\w+)?(?=\))");
    auto messageRegex = regex(r"(?<=:).*");
    auto headerMatch = commitString.matchFirst(headerRegex);
    string header = headerMatch.hit.strip;
    auto scopeMatch = headerMatch.post.matchFirst(scopeRegex);
    string zcope = scopeMatch.empty ? "" : scopeMatch.hit.strip;
    auto messageMatch = (scopeMatch.empty ? headerMatch.post : scopeMatch.post).matchFirst(
            messageRegex);
    string message = messageMatch.hit.strip;
    return scopeMatch.empty ? GitCommitSummary(header,
            message) : GitCommitSummary(header, zcope, message);
}

unittest
{
    string commit = "feat(git): test message";
    GitCommitSummary commitSummary = parseGitCommitLine(commit);
    assert(
        commitSummary.type == "feat"
        && !commitSummary.typeScope.isNull
        && commitSummary.typeScope.get == "git"
        && commitSummary.message == "test message"
    );
}

unittest
{
    string commit = "feat: test message";
    GitCommitSummary commitSummary = parseGitCommitLine(commit);
    assert(
        commitSummary.type == "feat"
        && commitSummary.typeScope.isNull
        && commitSummary.message == "test message"
    );
}

unittest
{
    string commit = "feat(github-actions): test message";
    GitCommitSummary commitSummary = parseGitCommitLine(commit);
    assert(
        commitSummary.type == "feat"
        && !commitSummary.typeScope.isNull
        && commitSummary.typeScope.get == "github-actions"
        && commitSummary.message == "test message"
    );
}

struct GitCommitSummary
{
    import std.typecons : Nullable;

    string type;
    Nullable!string typeScope;
    string message;

    this(string type, string typeScope, string message) @safe nothrow pure @nogc
    {
        this.type = type;
        this.typeScope = typeScope;
        this.message = message;
    }

    this(string type, string message) @safe nothrow pure @nogc
    {
        this.type = type;
        this.typeScope = Nullable!string();
        this.message = message;
    }
}

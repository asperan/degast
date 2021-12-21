module glparser;

GitCommitSummary[] getCommitSummaries()
{
    import std.process : executeShell;
    import std.stdio : stderr;
    import std.string : split, chomp;
    import std.algorithm.iteration : map;
    import std.array : array;
    import core.stdc.stdlib : exit;

    auto gitLogList = executeShell("git log --pretty=\"%s\"");
    if (gitLogList.status > 0)
    {
        stderr.writeln(gitLogList.output);
        return exit(gitLogList.status);
    }
    else
    {
        return gitLogList.output.chomp.split("\n").map!(s => parseGitCommitLine(s)).array;
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

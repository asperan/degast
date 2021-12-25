module shell_utils;

string getShellOutput(string command, string errorMessage)
{
    import std.process : executeShell;
    import std.stdio : stderr;
    import core.stdc.stdlib : exit;

    auto shellOutput = executeShell(command);
    if (shellOutput.status > 0)
    {
        stderr.writeln(errorMessage ~ "\n\t" ~ "Caused by: " ~ shellOutput.output);
        return exit(shellOutput.status);
    }
    else
    {
        import std.string : strip;
        return shellOutput.output.strip;
    }
}


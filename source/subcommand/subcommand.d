module subcommand.subcommand;

/**
 * A SubCommand interface to standardize subcommands.
 */
interface SubCommand
{
    /**
     * Parse the subcommand options.
     * Params:
     *   arguments = the argument list.
     */
    void parseOptions(string[] arguments);

    /**
     * Run the subcommand.
     */
    void run();

    /**
     * Get the command description for an help message.
     * Returns: a brief command description.
     */
    string getDescription();
}

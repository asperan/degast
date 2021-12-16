# DeGAST
## D enhanced Git Automation Simple Toolbox

degast is a software to help users apply the (conventional commit guidelines)[https://www.conventionalcommits.org/en/v1.0.0-beta.2/] to allow an easier automation.

### Run
```
dgst <subcommand> [subcommand options] [subcommand arguments]
```

### Subommands
#### commit
Start an interactive form to construct a commit. It requires no argument.

It asks for:

1. header type
2. scope (optional)
3. summary message
4. body of the message (optional)
5. footer of the message (optional)

##### options
* -nc, --no-confirm => do not ask confirmation and do not show the preview of the commit message

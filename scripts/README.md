# Scripts

## Bash Completion

To enable bash completion for `ops.sh`, add the following to your `~/.bashrc` or `~/.zshrc`:

```bash
# For bash
source /path/to/home-2021/scripts/ops-completion.bash

# For zsh (if using bash completion compatibility)
autoload -U +X bashcompinit && bashcompinit
source /path/to/home-2021/scripts/ops-completion.bash
```

After sourcing, you can use tab completion:
- `./ops.sh <TAB>` - shows available commands
- `./ops.sh up <TAB>` - shows available units
- `./ops.sh logs <TAB>` - shows available units


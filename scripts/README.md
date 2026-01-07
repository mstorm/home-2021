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

## Database Setup Scripts

### setup-zitadel-db.sh

Manually create Zitadel database and user for existing PostgreSQL instance.

**Usage:**
```bash
./scripts/setup-zitadel-db.sh
```

**Requirements:**
- PostgreSQL container must be running
- `etc/srv/data.postgres.env` must exist
- `etc/srv/foundation.zitadel.env` must exist

**Password Handling:**
- If `ZITADEL_DATABASE_PASSWORD` is already set in `etc/srv/foundation.zitadel.env`, it will be used
- If not set, the script will automatically generate a secure 32-character password
- **Important:** If a password is auto-generated, you must add it to `etc/srv/foundation.zitadel.env` for future use

**What it does:**
1. Creates `zitadel` database (if it doesn't exist)
2. Creates `zitadel` user with the specified/generated password
3. Grants all necessary privileges to the user

This script is useful when PostgreSQL was already initialized and you need to add the Zitadel database and user manually.


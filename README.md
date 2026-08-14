# bulk-file-organizer

A pure Bash tool that sorts a messy directory (e.g. `~/Downloads`) into
category folders — `Images`, `Documents`, `Videos`, `Audio`, `Archives`,
`Code`, `Others` — based on file extension. No dependencies beyond
coreutils and Bash.

## Features

- Sorts files by extension into category folders
- Optional date-based subfolders (`YYYY-MM`) within each category
- Collision-safe: never overwrites — appends `(1)`, `(2)`, etc.
- Dry-run mode to preview changes before touching anything
- Logs every action with a timestamp
- Fully configurable categories via `config.sh`
- One-command cron install for daily automated runs
- Shell-only test suite, no test framework required

## Usage

```bash
chmod +x organize.sh
./organize.sh -s ~/Downloads
```

### Options

| Flag | Description                                            | Default          |
|------|----------------------------------------------------------|-----------------|
| `-s` | Source directory to organize (required)                 | —                |
| `-t` | Target directory for organized folders                  | same as source   |
| `-c` | Path to config file                                      | `./config.sh`    |
| `-l` | Path to log file                                          | `./organize.log` |
| `-b` | Add `YYYY-MM` date subfolders inside each category        | off              |
| `-n` | Dry run — log what *would* happen without moving files    | off              |
| `-v` | Verbose — also print log lines to stdout                 | off              |
| `-h` | Show help                                                 | —                |

### Examples

Preview what would happen, verbosely, without moving anything:

```bash
./organize.sh -s ~/Downloads -n -v
```

Organize into a different target, with monthly subfolders:

```bash
./organize.sh -s ~/Downloads -t ~/Sorted -b
```

## Customizing categories

Edit `config.sh` to add, remove, or redefine categories:

```bash
CATEGORY_EXTENSIONS[Screenshots]="png"
CATEGORY_EXTENSIONS[Ebooks]="epub mobi azw3"
DEFAULT_CATEGORY="Misc"
```

Point at a different config with `-c /path/to/other-config.sh`.

## Automate with cron

```bash
chmod +x install.sh
./install.sh -s ~/Downloads -t 03:00
```

This installs (or replaces) a daily crontab entry. Remove it any time:

```bash
crontab -l | grep -vF '# bulk-file-organizer' | crontab -
```

## Tests

```bash
chmod +x tests/test_organize.sh
./tests/test_organize.sh
```

Runs a set of smoke tests in a temp directory covering categorization,
collision handling, and dry-run behavior.

## License

MIT — see [LICENSE](LICENSE).

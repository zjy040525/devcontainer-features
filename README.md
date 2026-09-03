# Dev Container Features

A collection of Dev Container Features published to GitHub Container Registry.

## Available Features

### Claude Config Persist

`claude-config-persist` keeps Claude Code configuration available across Dev Container rebuilds. It mounts configuration from the host, stores plugins in a named volume, and links the persisted state into the container user's home directory.

Add the Feature to `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {},
    "ghcr.io/zjy040525/devcontainer-features/claude-config-persist:1": {}
  }
}
```

Use `:1` to track the latest compatible `1.x` release, or use a full version such as `:1.0.0` for reproducible builds.

This Feature does not install Claude Code. The example includes the official Claude Code Feature separately.

#### Persisted State

| State                | Storage                                            |
| -------------------- | -------------------------------------------------- |
| `~/.claude/`         | Host `~/.claude/` directory                        |
| `~/.claude/plugins/` | Named Docker volume scoped by the Dev Container ID |
| `~/.claude.json`     | Host `~/.claude.json` file                         |

Existing configuration in the container user's home directory is copied into the persisted location before the symbolic links are created.

The host `~/.claude/` directory and `~/.claude.json` file must exist before the container is created. For example:

```sh
mkdir -p "$HOME/.claude"
touch "$HOME/.claude.json"
```

The mounted files can contain credentials and other sensitive data. Use this Feature only with trusted Dev Container configurations.

## Development

Install dependencies and prepare the local Feature used by this repository's Dev Container:

```sh
pnpm install
```

The `postinstall` script creates hard links from `src/claude-config-persist` to `.devcontainer/claude-config-persist`. Run `pnpm setup` to recreate them manually.

Run repository checks with:

```sh
pnpm lint
```

### IDE Support (auto fix on save)

<details>
<summary>🟦 VS Code support</summary>

<br>

Install [VS Code ESLint extension](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)

Add the following settings to your `.vscode/settings.json`:

```jsonc
{
  // Disable the default formatter, use eslint instead
  "prettier.enable": false,
  "editor.formatOnSave": false,

  // Auto fix
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.organizeImports": "never"
  },

  // Silent the stylistic rules in your IDE, but still auto fix them
  "eslint.rules.customizations": [
    { "rule": "style/*", "severity": "off", "fixable": true },
    { "rule": "format/*", "severity": "off", "fixable": true },
    { "rule": "*-indent", "severity": "off", "fixable": true },
    { "rule": "*-spacing", "severity": "off", "fixable": true },
    { "rule": "*-spaces", "severity": "off", "fixable": true },
    { "rule": "*-order", "severity": "off", "fixable": true },
    { "rule": "*-dangle", "severity": "off", "fixable": true },
    { "rule": "*-newline", "severity": "off", "fixable": true },
    { "rule": "*quotes", "severity": "off", "fixable": true },
    { "rule": "*semi", "severity": "off", "fixable": true }
  ],

  // Enable eslint for all supported languages
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "html",
    "markdown",
    "json",
    "json5",
    "jsonc",
    "yaml",
    "toml",
    "xml",
    "gql",
    "graphql",
    "astro",
    "svelte",
    "css",
    "less",
    "scss",
    "pcss",
    "postcss"
  ]
}
```

</details>

Feature metadata is also validated by GitHub Actions on every push and pull request.

## Releasing

Each directory under `src/` is an independently versioned Feature. Before publishing, update the `version` in each changed Feature's `devcontainer-feature.json` according to Semantic Versioning.

Publishing is manual:

1. Merge the version changes into `main`.
2. Open **Actions > Release Dev Container Features**.
3. Select **Run workflow**.

The release workflow validates the repository and publishes the Feature collection to `ghcr.io/zjy040525/devcontainer-features`.

## License

[MIT](LICENSE)

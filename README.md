# Tmux Open Anything

This is a Tmux plugin that opens a selected text in copy-mode with tools like a text editor or web browser.

## Features

There are currently four commands available:

- edit

   Opens the selected text as a pathname with the text editor defined by the `EDITOR` environment variable. (Default: `vi`)

- browse

   Opens the selected text as a URL with the web browser defined by the `BROWSER` environment variable. (Default: `open` or `xdg-open` depending on the platform)

- search

   Searches the web for the selected text with the web browser described in the "browse" command above.

- open

   Opens the selection with the web browser if it looks like a URL, or the text editor otherwise.

## Installation

Install the [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) and add this plugin like so:

```
set -g @plugin 'knu/tmux-open-anything'
```

## Configuration

- `@open-anything:bindings`

    Key bindings can be changed via this option.  Below is the default configuration.

    ```
    set -g @open-anything:bindings "\
    copy-mode o open
    copy-mode s search
    copy-mode-vi o open
    copy-mode-vi s search
    "
    ```

- `@open-anything:pipe-command`

    The pipe command to be used for commands bound by Open Anything, defaulted to `pipe-no-clear`.  Any other pipe/copy command such as `copy-pipe-no-clear` and `pipe-and-cancel` can be specified.

    ```
    set -g @open-anything:pipe-command pipe-no-clear
    ```

- `@open-anything:editor nvim`

    Alternative value for `EDITOR`.  Only the command name (without any flags) can be specified.

    ```
    set -g @open-anything:editor nvim
    ```

- `@open-anything:browser`

    Alternative value for `BROWSER`.  Use of a placeholder `%s` is supported.

    ```
    set -g @open-anything:browser "open -a /Applications/Arc.app %s"
    ```

- `@open-anything:search-url`

    The search engine URL for the "search" command.  It is Google by default.  Use of a placeholder `%s` is supported.

    ```
    set -g @open-anything:search-url 'https://www.google.com/search?q='

    set -g @open-anything:search-url 'https://www.duckduckgo.com/?q=%s'
    ```

## Author

Copyright (c) 2023 Akinori MUSHA.

Licensed under the 2-clause BSD license.  See `LICENSE.txt` for details.

Visit [GitHub Repository](https://github.com/knu/tmux-open-anything) for the latest information.

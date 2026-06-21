# sdcv-pure.el

This is an alternative Elisp implementation of `sdcv.el` that does not require the `sdcv` CLI dependency. It is based on [Chen Bin](https://github.com/redguardtoo)'s code from [here](https://github.com/redguardtoo/emacs.d/blob/be57e47c974015bb4623b1d32f41fed5b126d229/lisp/init-dictionary.el).

This version includes updates to support lookups across multiple dictionaries.

## Installation

Clone the repository and add it to your `load-path`:

```elisp
(add-to-list 'load-path "/path/to/sdcv-pure.el")
(require 'sdcv-pure)
```

## Usage

Use,

- `sdcv-simple-definition` for popup lookup with dictionary cycling
- `sdcv-complete-definition` for the multiple dictionaries lookup in a buffer
- `sdcv-select-definition` for popup lookup with a specific dictionary you choose

### Popup Dictionary Cycling (sdcv-simple-definition)

When using `sdcv-simple-definition`, the result is displayed as a popup overlay starting with `sdcv-simple-dict`. You can cycle through other dictionaries defined in `sdcv-multiple-dicts` using:

- `C-j` - Show result from the next dictionary
- `C-k` - Show result from the previous dictionary
- `y` - Copy the current definition to the kill ring
- Any other key - Dismiss the popup

Dictionaries are looked up lazily — only when you navigate to them. Results are cached in memory so cycling back is instant.

### Select Dictionary (sdcv-select-definition)

Prompts you to select a dictionary from `sdcv-multiple-dicts`, then looks up the word and displays it in the same popup overlay with the same keybindings as above.

### Lookup History

Set `sdcv-history-file` to a file path to record every word you look up:

```elisp
(setq sdcv-history-file "~/sdcv-history.txt")
```

Words are stored one per line, newest first. Duplicate lookups are moved to the top rather than creating duplicates. When `sdcv-history-file` is nil (default), no history is recorded.

### Buffer Navigation (sdcv-complete-definition)

When using `sdcv-complete-definition`, you can quickly jump between different dictionaries in the results buffer using the following keybindings:

- `C-j` - Jump to the next dictionary entry
- `C-k` - Jump to the previous dictionary entry
- `q` - Quit the sdcv window

These keybindings are also available in Evil normal mode if you use Evil.

## License

`sdcv.el` is licensed under the GPL 3.0 License. See LICENSE for details.

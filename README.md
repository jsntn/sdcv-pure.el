# sdcv-pure.el

This is an alternative Elisp implementation of `sdcv.el` that does not require the `sdcv` CLI dependency. It is based on [Chen Bin](https://github.com/redguardtoo)'s code from [here](https://github.com/redguardtoo/emacs.d/blob/be57e47c974015bb4623b1d32f41fed5b126d229/lisp/init-dictionary.el).

This version includes updates to support lookups across multiple dictionaries.

## Installation

It can be installed using [straight.el](https://github.com/radian-software/straight.el). To install, add the following to your Emacs configuration file:

```emacs
(use-package sdcv-pure
  :straight (:host github :repo "jsntn/sdcv-pure.el")
  :config

  ;; set your dictionaries, see example below,
  ;; (defvar sdcv-simple-dict
  ;;   `("~/.stardict/dic/stardict-lazyworm-ec-2.4.2")
  ;;   "Dictionary to search")
  ;; (defvar sdcv-multiple-dicts
  ;;   `(("~/.stardict/dic/stardict-lazyworm-ec-2.4.2")
  ;;     ("~/.stardict/dic/stardict-langdao-ce-gb-2.4.2")
  ;;     ("~/.stardict/dic/stardict-langdao-ec-gb-2.4.2")
  ;;     ("~/.stardict/dic/stardict-cedict-gb-2.4.2")
  ;;     ("~/.stardict/dic/stardict-DrEye4in1-2.4.2"))
  ;;   "List of dictionaries to search.")

  ;; keybinding example,
  ;; (global-set-key (kbd "C-c d") 'sdcv-simple-definition)
  ;; (global-set-key (kbd "C-c D") 'sdcv-complete-definition)
  )
```

## Usage

Use,

- `sdcv-simple-definition` for popup lookup with dictionary cycling
- `sdcv-complete-definition` for the multiple dictionaries lookup in a buffer

### Popup Dictionary Cycling (sdcv-simple-definition)

When using `sdcv-simple-definition`, the result is displayed as a popup overlay starting with `sdcv-simple-dict`. You can cycle through other dictionaries defined in `sdcv-multiple-dicts` using:

- `C-j` - Show result from the next dictionary
- `C-k` - Show result from the previous dictionary
- Any other key - Dismiss the popup

Dictionaries are looked up lazily — only when you navigate to them. Results are cached in memory so cycling back is instant.

### Buffer Navigation (sdcv-complete-definition)

When using `sdcv-complete-definition`, you can quickly jump between different dictionaries in the results buffer using the following keybindings:

- `C-j` - Jump to the next dictionary entry
- `C-k` - Jump to the previous dictionary entry
- `q` - Quit the sdcv window

These keybindings are also available in Evil normal mode if you use Evil.

## License

`sdcv.el` is licensed under the GPL 3.0 License. See LICENSE for details.

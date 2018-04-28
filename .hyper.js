// Future versions of Hyper may add additional config options,
// which will not automatically be merged into this file.
// See https://hyper.is#cfg for all currently supported options.
const foregroundColor = '#f8f8f2'
const backgroundColor = '#282a36'
const black = '#44475a'
const red = '#ff5555'
const green = '#50fa7b'
const yellow = '#f1fa8c'
const blue = '#bd93f9'
const magenta = '#ff79c6'
const cyan = '#8be9fd'
const gray = '#666666'
const brightBlack = '#999999'
const brightWhite = '#ffffff'

module.exports = {
  config: {
    updateChannel: 'canary',
    // default font size in pixels for all tabs
    fontSize: 17,

    // font family with optional fallbacks
    fontFamily: '"Inconsolata for Powerline", Menlo, "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',

    // terminal cursor background color and opacity (hex, rgb, hsl, hsv, hwb or cmyk)
    cursorColor: 'rgba(248,28,229,0.8)',

    // `BEAM` for |, `UNDERLINE` for _, `BLOCK` for █
    cursorShape: 'BLOCK',

    // set to true for blinking cursor
    cursorBlink: false,

    // border color (window, tabs)
    borderColor: '#333',

    backgroundImage: "/Users/Justin/Downloads/tenor.gif",
    // custom css to embed in the main window
    css: `
    .header_header {
        background: transparent;
    }

    .tab_tab{
      background: black;
      border: none;
    }

    .tabs_title{
      font-size 14px;
    }

    .tab_text{
      font-size 14px;
    }

    .tabs_list .tab_tab.tab_active .tab_text  {
      background: ${backgroundColor};
    }
    .tab_active:before {
      border-color: rgb(68, 71, 90);
    }
    `,

    // custom css to embed in the terminal window
    termCSS: '',

    // set to `true` (without backticks) if you're using a Linux setup that doesn't show native menus
    // default: `false` on Linux, `true` on Windows (ignored on macOS)
    showHamburgerMenu: '',

    // set to `false` if you want to hide the minimize, maximize and close buttons
    // additionally, set to `'left'` if you want them on the left, like in Ubuntu
    // default: `true` on windows and Linux (ignored on macOS)
    showWindowControls: 'false',

    // custom padding (css format, i.e.: `top right bottom left`)
    //padding: '12px 14px',
    padding: '1px 0px 0px 2px',

    // the full list. if you're going to provide the full color palette,
    // including the 6 x 6 color cubes and the grayscale map, just provide
    // an array here instead of a color map object
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    borderColor: black,
    cursorColor: brightBlack,
    colors: [
      black,
      red,
      green,
      yellow,
      blue,
      magenta,
      cyan,
      gray,

      // bright
      brightBlack,
      red,
      green,
      yellow,
      blue,
      magenta,
      cyan,
      brightWhite
    ],
    // the shell to run when spawning a new session (i.e. /usr/local/bin/fish)
    // if left empty, your system's login shell will be used by default
    // make sure to use a full path if the binary name doesn't work
    // (e.g `C:\\Windows\\System32\\bash.exe` instead of just `bash.exe`)
    // if you're using powershell, make sure to remove the `--login` below
    shell: '',

    // for setting shell arguments (i.e. for using interactive shellArgs: ['-i'])
    // by default ['--login'] will be used
    shellArgs: ['--login'],

    // for environment variables
    env: {},

    // set to false for no bell
    bell: 'false',

    // if true, selected text will automatically be copied to the clipboard
    copyOnSelect: false,

    // if true, on right click selected text will be copied or pasted if no
    // selection is present (true by default on Windows)
    // quickEdit: true

    // URL to custom bell
    // bellSoundURL: 'http://example.com/bell.mp3',

    // for advanced config flags please refer to https://hyper.is/#cfg
    hypercwd: {
      initialWorkingDirectory: '~'
    }
  },
  keymaps: {
    "editor:moveBeginningLine": "",
    "editor:moveEndLine": "",
    "tab:prev": [
      "ctrl+shift+[",
      "cmd+left"
    ],
    "tab:next": [
      "ctrl+shift+]",
      "cmd+right"
    ],
  },
  // a list of plugins to fetch and install from npm
  // format: [@org/]project[#version]
  // examples:
  //   `hyperpower`
  //   `@company/project`
  //   `project#1.0.1`
  plugins: ["hyper-search",
            "hypercwd",
            "space-pull",
            "gitrocket",
            "hyper-tab-icons"],
  // in development, you can create a directory under
  // `~/.hyper_plugins/local/` and include it here
  // to load it and avoid it being `npm install`ed
  localPlugins: [
  ]
};

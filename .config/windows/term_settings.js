const fs = require('fs');
const path = require('path');
const { json } = require('stream/consumers');

let settings_file = path.resolve(
    process.env.LOCALAPPDATA,
    "Packages",
    "Microsoft.WindowsTerminal_8wekyb3d8bbwe",
    "LocalState",
    "settings.json"
  );

let settings = JSON.parse(
    fs
    .readFileSync(settings_file)
    .toString()
);

let dracula = {
  background: "#272935",
  black: "#272935",
  blue: "#BD93F9",
  brightBlack: "#555555",
  brightBlue: "#BD93F9",
  brightCyan: "#8BE9FD",
  brightGreen: "#50FA7B",
  brightPurple: "#FF79C6",
  brightRed: "#FF5555",
  brightWhite: "#FFFFFF",
  brightYellow: "#F1FA8C",
  cursorColor: "#FFFFFF",
  cyan: "#6272A4",
  foreground: "#F8F8F2",
  green: "#50FA7B",
  name: "Dracula",
  purple: "#6272A4",
  red: "#FF5555",
  selectionBackground: "#FFFFFF",
  white: "#F8F8F2",
  yellow: "#FFB86C",
};

let defaults = {
    colorScheme: "Dracula",
    font: {
        face: "CaskaydiaCove Nerd Font Mono"
    }
};

settings.schemes.push(dracula);
settings.profiles.defaults = defaults;

fs.writeFileSync(JSON.stringify(settings));

console.log("Updated Windows Terminal settings.")
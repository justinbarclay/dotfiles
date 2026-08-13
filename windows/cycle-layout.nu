#!/usr/bin/env nu
# Cycles the focused workspace through Rows -> BSP -> Columns -> Floating -> Rows ...
# komorebic has no native concept that spans tiled layouts and the floating
# (tile: false) state, so this stitches change-layout/toggle-tiling together
# based on the workspace's current state.
#
# Usage:  nu cycle-layout.nu [next|previous]

def main [direction: string = "next"] {
    let layouts = ["Rows", "BSP", "Columns"]
    let floating_state = ($layouts | length)
    let total_states = $floating_state + 1

    let state = (komorebic state | from json)
    let monitor = ($state.monitors.elements | get $state.monitors.focused)
    let workspace = ($monitor.workspaces.elements | get $monitor.workspaces.focused)

    let current_state = if $workspace.tile {
        let idx = ($layouts | enumerate | where item == $workspace.layout.Default | get index)
        if ($idx | is-empty) { 0 } else { $idx | first }
    } else {
        $floating_state
    }

    let step = if $direction == "next" { 1 } else { -1 }
    let next_state = (($current_state + $step) mod $total_states + $total_states) mod $total_states

    if $next_state == $floating_state {
        if $workspace.tile {
            komorebic toggle-tiling
        }
    } else {
        if not $workspace.tile {
            komorebic toggle-tiling
        }
        komorebic change-layout ($layouts | get $next_state | str lowercase)
    }
}

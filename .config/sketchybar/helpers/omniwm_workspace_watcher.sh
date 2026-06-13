#!/bin/sh

omniwmctl watch active-workspace,workspace-bar,layout-changed,windows-changed \
  --exec sketchybar --trigger omniwm_workspace_change

omniwmctl watch active-workspace workspace-bar windows-changed layout-changed \
  --exec /opt/homebrew/bin/sketchybar --trigger omniwm_workspace_change

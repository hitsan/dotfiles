# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview
This is a Home Manager configuration for user `hitsan` on `x86_64-linux`. It contains modular configurations for development tools, editors, shell, git, and other user applications.

## Commands
- Update Home Manager: `home-manager switch --flake ~/dotfiles#hitsan` (aliased as `home` and `hflake`)
- Update flake: `nix flake update`
- Lint: `nixpkgs-fmt *.nix`
- Check configuration: `nix flake check`

## Code Style Guidelines
- **Formatting**: Use 2-space indentation for Nix files
- **Imports**: Group imports logically by category (home-manager, pkgs, lib, etc.)
- **Naming**: Use camelCase for variables, snake_case for paths
- **File Organization**: 
  - Place user configurations in `/modules/{category}`
  - Use `default.nix` files for module organization
  - Keep related configurations together (e.g., git + gh + lazygit)
- **Error Handling**: Use `lib.mkIf` for conditional configurations
- **Documentation**: Add comments for non-obvious configurations

## Module Structure
- `dev/` - Development tools (claude, direnv, just)
- `docker/` - Docker and container tools
- `editor/` - Text editors (neovim, typst)
- `git/` - Git configuration and related tools
- `shell/` - Shell and terminal configuration (zsh, alacritty)
- `zellij/` - Terminal multiplexer configuration
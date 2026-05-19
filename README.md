# Premium Terminal Shader Engine

A macOS Swift + Metal application that renders premium animated shader backgrounds for terminal use, with five cinematic presets, subtle typing reactivity, and Homebrew-based installation.

## Features

- Five shader presets:
  - Spaceflight
  - Night-Sky-Flight
  - Morning-Sky-Flight
  - Ocean-Wave-Flight
  - Aurora-Drift
- Terminal-safe, low-contrast visuals
- Subtle typing-reactive motion
- Swift + Metal rendering pipeline
- Homebrew tap installation

## Goals

This project is designed to create a premium terminal background experience that feels cinematic, atmospheric, and fluid while keeping terminal text readable at all times.

## Installation

Install via Homebrew:

```bash
brew tap <your-org>/<your-tap>
brew install <formula-name>
```

## Usage

After installation, launch the app and select a preset from the settings UI.

Example:

```bash
<app-command-or-app-launch-command>
```

## Presets

### Spaceflight
A 3D starfield with forward motion, depth, and warp-through-space feel.

### Night-Sky-Flight
A low-contrast volumetric night cloudscape.

### Morning-Sky-Flight
A soft dawn atmosphere with warm light scattering.

### Ocean-Wave-Flight
A perspective ocean plane with subtle rolling waves.

### Aurora-Drift
A 3D aurora simulation with flowing luminous curtains.

## Architecture

- `App/` — app lifecycle, UI, settings, state
- `Rendering/` — Metal renderer and shared graphics utilities
- `Presets/` — shader preset implementations
- `Packaging/` — Homebrew tap and release files
- `Docs/` — PRD, CLAUDE, and supporting documentation

## Development

This project is intended to stay modular, readable, and performance-conscious.

- Keep terminal readability as the top priority.
- Keep preset behavior aligned with the PRD.
- Prefer minimal, clean changes over broad refactors.

## Repository files

- `PRD.md` — product and behavior specification
- `CLAUDE.md` — implementation rules for Claude Code
- `README.md` — project overview and usage
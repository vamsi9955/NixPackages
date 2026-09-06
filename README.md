# 📦 NixPackages

A personal, automated software factory and Nix flake for hosting custom Homelab applications, modules, and utilities that are not available in the official Nixpkgs repository.

## ⚙️ Automated Workflows

This repository is governed by two interconnected GitHub Actions that keep the software stack bleeding-edge without manual intervention:

### 1. Auto-Update & Release (`update-and-release.yml`)
* **Trigger:** Runs daily at 06:00 UTC (or manually via `workflow_dispatch`).
* **Function:** Iterates through all tracked packages and utilizes `nix-update` to query upstream GitHub repositories for new releases.
* **Resolution:** If a new release is found, it automatically calculates the new source hashes, performs the PNPM/NPM lockfile hash-dance, commits the updated `.nix` files, and publishes a consolidated GitHub Release containing the upstream changelogs.

### 2. Build & Cache (`build-and-cache.yml`)
* **Trigger:** Automatically runs whenever a new GitHub Release is published by the Auto-Updater.
* **Function:** Spools up a matrix of parallel Ubuntu runners to compile every updated package using Nix.
* **Resolution:** Pushes the finalized, compiled binaries directly to Cachix. 

## 🚀 Usage in NixOS

Add this repository as an input to your system flake:

```nix
inputs = {
  my-packages.url = "github:vamsi9955/NixPackages";
};

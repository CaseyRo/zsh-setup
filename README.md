# ZSH-Manager: The Ultimate Cross-Platform ZSH Configuration Framework

## 🚀 Introduction

**ZSH-Manager** is a powerful, lightweight, and flexible framework that enables you to maintain a single, unified ZSH configuration across **Linux, macOS, and Windows**. Designed for developers, system administrators, and power users, ZSH-Manager ensures a **consistent shell experience** across all operating systems.

## 🔥 Why Choose ZSH-Manager?

- ✅ **Seamless Cross-Platform Support**: Works flawlessly on **Linux, macOS, and Windows**.
- ✅ **Support Environment variables**: Easy and extensive way to use Environment variables.
- ✅ **Path Handling**: Easy and extensive way to handle Path variables.
- ✅ **Portable & Unified ZSH Configuration**: Manage all your shell settings from one place.
- ✅ **Customizable & Modular**: Use preloaded configurations and extend functionality with custom modules.
- ✅ **Compatible with All ZSH Frameworks**: Supports **Oh-My-Zsh, Prezto, Antigen, and Zim**.
- ✅ **Lightweight & Fast**: Minimal dependencies, designed for performance.
- ✅ **Effortless Synchronization**: Easily sync your settings via **Git, Dropbox, or cloud services**.
- ✅ **Automated Setup**: Quickly set up using the provided **symlink script**.

## 🏗️ Directory Structure

```
zsh-manager/
├── README.md                           # Documentation
├── bootstrap.sh                        # One-liner remote install script
├── install.sh                          # Full setup script with progress bar
├── run-to-symlink.sh                   # Quick symlink-only setup
├── .zshrc                              # Main ZSH configuration file
├── install/                            # Installation modules
│   ├── packages.sh                     # Package lists (brew, cargo, npm)
│   ├── utils.sh                        # CLI styling and progress bar
│   ├── brew.sh                         # Homebrew installation
│   ├── rust.sh                         # Rust/Cargo installation
│   ├── nvm.sh                          # NVM installation
│   └── oh-my-zsh.sh                    # Oh My Zsh installation
├── preload_configs/                    # OS-specific preloaded configurations
│   ├── common/                         # Shared configurations
│   ├── linux/                          # Linux-specific configs
│   ├── macos/                          # macOS-specific configs
│   └── windows/                        # Windows-specific configs
├── modules/                            # Custom modules (aliases, functions, etc.)
│   ├── common/                         # Cross-platform modules
│   ├── linux/                          # Linux-specific modules
│   ├── macos/                          # macOS-specific modules
│   └── windows/                        # Windows-specific modules
```

## 📦 Installation & Setup

### Quick Install (Recommended)

Run this one-liner to install everything on a fresh machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/CaseyRo/zsh-manager/main/bootstrap.sh)"
```

This will:
- Clone zsh-manager to `~/.zsh-manager`
- Install Homebrew, Rust, NVM, and Oh My Zsh
- Install git, GitHub CLI (gh), and btop (system monitor)
- Install CLI tools via Cargo (bat, eza, ripgrep, fd, zoxide, topgrade)
- Install Docker & Docker Compose (Linux only)
- Install Node.js stable and global npm packages
- Install Nerd Fonts for terminal glyphs (desktop only)
- Set up your `.zshrc` symlink

**Raspberry Pi / ARM Linux**: Automatically detected! Uses APT for pre-built packages instead of compiling from source.

### Manual Installation

#### 1️⃣ Clone the Repository

```bash
git clone git@github.com:CaseyRo/zsh-manager.git ~/.zsh-manager
```

#### 2️⃣ Run the Setup Script
```bash
cd ~/.zsh-manager
./install.sh
```

Optional UI flags:
```bash
./install.sh --ui gum --theme minimal
```

Environment alternatives:
```bash
NO_COLOR=1 ZSH_MANAGER_UI=plain ./install.sh
```

#### 3️⃣ Customize Your Configuration

- Add **OS-specific** preloaded configs in `preload_configs/`
- Add **OS-specific** Environment/Path configs in `preload_configs/*os*/path.sh`
- Extend functionality with **custom modules** in `modules/`
- Edit package lists in `install/packages.sh`

## ⚙️ How ZSH-Manager Works

### **1️⃣ Dynamic Configuration Loading**
ZSH-Manager **automatically detects your operating system** and loads the appropriate configurations.

- **Common settings** (`preload_configs/common/`) are loaded first.
- **OS-specific settings** (`preload_configs/linux/`, `macos/`, `windows/`) are applied afterward.

### **2️⃣ Modular Architecture**
- Store **custom functions, aliases, and scripts** in `modules/`.
- Modules are categorized into **common** and **OS-specific** folders.
- Ignore specific modules or configurations by **prefixing folder names with `#`** (e.g., `#ignored_module/`).

### **3️⃣ Symlink-Based Setup**
- The **setup script** (`run-to-symlink.sh`) automatically links `.zshrc` to the framework.
- This allows **easy switching** between configurations without modifying system files.

## 🎯 Key Features

### 🔗 **Cross-Platform Compatibility**
- Works seamlessly on **Linux, macOS, and Windows (WSL, Git Bash, Cygwin, MSYS2)**.

### 🔄 **Auto-Loading of Preloaded Configurations**
- Automatically loads common and OS-specific **aliases, functions, and environment variables**.

### 🎨 **Custom Modules & Plugins Support**
- Organize your scripts with a modular structure.
- Supports **any additional ZSH plugins or external tools**.

### 🏎️ **Optimized for Speed & Performance**
- **Lightweight** with minimal overhead.
- **Fast execution** with optimized loading logic.

### ☁️ **Sync Anywhere**
- Easily sync configurations across devices using **Git, Dropbox, or cloud services**.

### 🛠️ **Works with Any ZSH Framework**
- Compatible with **Oh-My-Zsh, Prezto, Antigen, Zim, and more**.

### 🧩 **Fully Customizable**
- Add, remove, or modify configurations as needed.
- Ignore specific scripts or modules by naming them with `#`.

## 🛠️ Usage

### **Adding Custom Modules**
Place your custom ZSH scripts inside the corresponding **modules/** folder:

```bash
modules/
├── common/
│   ├── aliases.sh         # Shared aliases
│   ├── functions.sh       # Shared functions
│   └── startup.sh         # Commands run on shell start (e.g., fastfetch)
├── linux/
│   └── linux_aliases.sh   # Linux-specific aliases
├── macos/
│   └── macos_shortcuts.sh # macOS-specific functions
└── windows/
    └── win_helpers.sh     # Windows-specific helpers
```

### **Ignoring Folders & Scripts**
To prevent specific scripts from being loaded, **prefix the filename or folder with `#`**:

```bash
modules/
├── common/
│   ├── aliases.sh
│   ├── #deprecated_aliases.sh  # This file will be ignored
│   ├── #old_scripts/           # This folder will be ignored
```

### **Using Environment variables**
Place your env variables inside your home directory **~/.env.sh** folder:
```bash
export ENV_VAR1="Value1"
```

## 🤝 Contributing
We welcome contributions! Feel free to submit issues, feature requests, or pull requests.

## 📜 License
ZSH-Manager is open-source and available under the **MIT License**.

---

## 📋 Changelog

### v2.0.0 (January 2026)

#### New Features
- **One-liner installation**: Run `curl ... | sh` to set up a fresh machine instantly
- **Sticky progress bar**: Setup script now shows a progress bar fixed at the bottom of the terminal while installation output scrolls above
- **Bootstrap script**: New `bootstrap.sh` for remote installation
- **Raspberry Pi / ARM Linux support**: Automatic detection uses APT for pre-built packages instead of slow compilation
- **Docker & Docker Compose**: Automatically installed on Linux (skipped on macOS)
- **Nerd Fonts**: Installs FiraMono, JetBrainsMono, and Meslo Nerd Fonts on desktop systems (skipped on headless/servers). Customize in `install/packages.sh`

#### Changes
- **Cargo-first package installation**: Moved core CLI tools from Homebrew to Cargo for better cross-platform consistency:
  - `bat` - cat with syntax highlighting
  - `eza` - modern ls replacement
  - `ripgrep` - fast grep (rg)
  - `fd-find` - fast find (fd)
  - `zoxide` - smarter cd
  - `topgrade` - system updater
- **Faster system info**: Replaced `hyfetch` with `fastfetch` (written in C, significantly faster startup)
- **Improved terminal handling**: Setup script now properly resets terminal on Ctrl+C interrupt

#### Platform-specific installation
| Platform | Package Manager | Docker |
|----------|----------------|--------|
| macOS | Homebrew + Cargo | No |
| Linux x86 | Homebrew + Cargo | Yes (brew) |
| Raspberry Pi / ARM | APT + minimal Cargo | Yes (apt) |

#### Homebrew packages (macOS/Linux x86)
- `zsh` - shell itself
- `git` - version control
- `gh` - GitHub CLI
- `fzf` - fuzzy finder (keybindings install better via brew)
- `byobu` - terminal multiplexer
- `fastfetch` - fast system info display

#### APT packages (Raspberry Pi / ARM Linux)
- Pre-built: `zsh`, `git`, `gh`, `fzf`, `byobu`, `bat`, `fd-find`, `ripgrep`, `fastfetch`
- Via Cargo (only what's not in APT): `eza`, `zoxide`, `topgrade`

---

🔥 **Start using ZSH-Manager today and streamline your ZSH configuration across all platforms!** 🚀

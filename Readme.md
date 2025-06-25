# Brida Prerequisities Installation Script

An automated bash script to set up a complete Brida development environment on Kali Linux with precise version control and proper isolation between virtual environment and system-wide components.
Setting up Brida is a pain in the ass and starting from the Frida version 17, it has changed a lot according to the frida blog, brida version 0.6 is not compatible with the latest version of frida. 
So, this script will install the working stable version of python, frida and frida-tools that are well compatible with Brida version 0.6
Frida API Version Changes - https://frida.re/news/2025/05/17/frida-17-0-0-released/

## 🎯 What This Script Does

This script automatically installs and configures:

- **Python 3.11.0** (compiled from source)
- **Virtual Environment** with Frida tools (isolated in `~/Downloads/brida`)
- **Frida 16.7.12** (Python library)
- **Frida-tools 13.2.1** (command-line tools)
- **Pyro4** (Python remote objects)
- **Node.js** (latest LTS)
- **frida-compile 10.2.5** (system-wide via npm)

## 🏗️ Architecture

```
System-wide:
├── Python 3.11.0 (/usr/local/bin/python3.11)
├── Node.js (latest LTS)
└── frida-compile 10.2.5 (npm global)

Virtual Environment (~/Downloads/brida/venv):
├── Python 3.11.0 (isolated)
├── Frida 16.7.12
├── frida-tools 13.2.1
└── Pyro4
```

## 🚀 Quick Start

### 1. Download the Script

```bash
# Clone the repository
git clone https://github.com/yourusername/kali-frida-setup.git
cd kali-frida-setup

# Or download directly
wget https://raw.githubusercontent.com/yourusername/kali-frida-setup/main/setup_kali_env.sh
```

### 2. Make Executable

```bash
chmod +x setup_kali_env.sh
```

### 3. Run the Script

```bash
./setup_kali_env.sh
```

The script will:
- Show you what will be installed
- Ask for confirmation before proceeding
- Handle all dependencies automatically
- Provide detailed progress logs

## 🎛️ Smart Version Management

### Python 3.11 Handling
- ✅ **Keeps Python 3.11.0** if already installed
- ⚠️ **Removes other 3.11.x versions** (3.11.1, 3.11.9, etc.)
- 🆕 **Installs 3.11.0 from source** if not present

### frida-compile Handling
- ✅ **Keeps 10.2.5** if already installed system-wide
- ⚠️ **Replaces other versions** with 10.2.5
- 🔄 **Uses npm global installation** (not the venv version)

### Virtual Environment
- 🧹 **Always recreates** `~/Downloads/brida` directory
- 🔒 **Isolates all Python packages** from system
- ✅ **Verifies exact versions** after installation

## 📁 Directory Structure

After successful installation:

```
~/Downloads/brida/
├── venv/
│   ├── bin/
│   │   ├── python -> python3.11.0
│   │   ├── pip
│   │   └── frida (frida-tools 13.2.1)
│   └── lib/python3.11/site-packages/
│       ├── frida/ (16.7.12)
│       ├── frida_tools/ (13.2.1)
│       └── Pyro4/
```

## 🔧 Usage

### Activate the Environment

```bash
cd ~/Downloads/brida
source venv/bin/activate
```

### Verify Installation

```bash
# Check Python version
python --version
# Output: Python 3.11.0

# Check Frida
python -c "import frida; print(f'Frida {frida.__version__}')"
# Output: Frida 16.7.12

# Check frida-tools
frida --version
# Output: 13.2.1

# Check system-wide frida-compile
which frida-compile
# Output: /usr/local/bin/frida-compile (or similar system path)

npm list -g frida-compile
# Output: frida-compile@10.2.5
```

### Deactivate Environment

```bash
deactivate
```

```

### Logs and Debugging

The script provides colored, timestamped logs:
- 🔵 **[INFO]**: General progress
- 🟢 **[SUCCESS]**: Completed steps
- 🟡 **[WARNING]**: Non-critical issues
- 🔴 **[ERROR]**: Critical failures

### Manual Cleanup

If needed, clean up manually:
```bash
# Remove virtual environment
rm -rf ~/Downloads/brida

# Remove Python 3.11.0 (if needed)
sudo rm -rf /usr/local/bin/python3.11*
sudo rm -rf /usr/local/lib/python3.11
sudo rm -rf /usr/local/include/python3.11

# Remove system-wide frida-compile
sudo npm uninstall -g frida-compile
```

## ✅ Verification Checklist

After running the script, verify:

- [ ] `python3.11 --version` shows "Python 3.11.0"
- [ ] Virtual environment directory exists: `~/Downloads/brida/venv`
- [ ] Frida imports successfully in venv: `python -c "import frida"`
- [ ] Frida-tools works in venv: `frida --version`
- [ ] System frida-compile exists: `which frida-compile`
- [ ] System frida-compile version: `npm list -g frida-compile`


## ⚠️ Disclaimer

This script modifies system packages and compiles software from source. While tested on Kali Linux, use at your own risk. Always review the script before running on production systems.


**Made with ❤️ for the InfoSec Community**

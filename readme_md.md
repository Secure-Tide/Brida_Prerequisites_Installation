# Kali Linux Frida Development Environment Setup

An automated bash script to set up a complete Frida development environment on Kali Linux with precise version control and proper isolation between virtual environment and system-wide components.

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

## 📋 Prerequisites

- **Kali Linux** (tested on latest version)
- **Internet connection** for downloading packages
- **Sudo privileges** (script will check and prompt)
- **At least 2GB free space** for compilation

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

## 🛠️ Troubleshooting

### Common Issues

#### Permission Errors During Cleanup
```
rm: cannot remove '/tmp/tmpXXX/Python-3.11.0/...': Permission denied
```
**Solution**: These are non-critical cleanup warnings. The script continues normally.

#### Python Compilation Takes Long
**Expected**: Python compilation can take 10-15 minutes depending on your system.

#### frida-compile Version Conflicts
If you see venv frida-compile in PATH:
```bash
# Use system-wide version explicitly
$(npm bin -g)/frida-compile --version
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

## 🔄 Updating

To update or reinstall:

1. **Full reinstall**: Run the script again (it will clean and reinstall)
2. **Partial update**: Manually update specific components

```bash
# Update only Frida in venv
cd ~/Downloads/brida
source venv/bin/activate
pip install --upgrade frida==16.7.12

# Update system frida-compile
sudo npm update -g frida-compile@10.2.5
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on clean Kali Linux installation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This script modifies system packages and compiles software from source. While tested on Kali Linux, use at your own risk. Always review the script before running on production systems.

## 🆘 Support

- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check this README and script comments

## 📊 Compatibility

| OS | Status | Notes |
|---|---|---|
| Kali Linux 2024.x | ✅ Tested | Primary target |
| Kali Linux 2023.x | ✅ Compatible | Should work |
| Debian 12+ | 🟡 Untested | May work with modifications |
| Ubuntu 22.04+ | 🟡 Untested | May work with modifications |

## 🔖 Version History

- **v1.0.0**: Initial release with full automation
- **v1.1.0**: Added smart version detection
- **v1.2.0**: Improved error handling and logging
- **v1.3.0**: Enhanced virtual environment isolation

---

**Made with ❤️ for the InfoSec Community**
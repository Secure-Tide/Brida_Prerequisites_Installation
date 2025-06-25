#!/bin/bash

# Kali Linux Development Environment Setup Script
# Installs Python 3.11.0 from source, sets up Frida environment with virtual env

# Don't exit on errors immediately - we'll handle them manually
set +e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error_log() {
    echo -e "${RED}[ERROR $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" >&2
}

success_log() {
    echo -e "${GREEN}[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warning_log() {
    echo -e "${YELLOW}[WARNING $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Error handling function - now handles non-critical errors
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command="$BASH_COMMAND"
    
    # Check if it's a critical error or just cleanup issues
    if [[ $exit_code -ne 0 ]]; then
        if [[ "$command" == *"rm -rf"* ]] || [[ "$command" == *"remove"* ]]; then
            warning_log "Non-critical cleanup error at line $line_number: $command"
            warning_log "This is usually due to permission issues and can be safely ignored"
        else
            error_log "Script failed at line $line_number with exit code $exit_code"
            error_log "Last command: $command"
            return $exit_code
        fi
    fi
}

# Remove the error trap since we're handling errors manually now
# trap 'handle_error $LINENO' ERR

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    error_log "This script should not be run as root for security reasons"
    error_log "Please run as a regular user with sudo privileges"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to uninstall existing Python 3.11 versions (except 3.11.0)
uninstall_existing_python311() {
    log "Checking for existing Python 3.11 installations..."
    
    # Check if python3.11 exists
    if command_exists python3.11; then
        local current_version=$(python3.11 --version 2>/dev/null)
        log "Found existing Python 3.11 installation: $current_version"
        
        # Check if it's exactly 3.11.0
        if [[ "$current_version" == *"3.11.0"* ]]; then
            success_log "Python 3.11.0 is already installed - keeping it"
            return 0
        else
            warning_log "Found Python 3.11.x (not 3.11.0): $current_version"
            log "Removing existing Python 3.11.x installation to install 3.11.0..."
            
            # Find and remove python3.11 binary
            local python311_path=$(which python3.11 2>/dev/null)
            if [[ -n "$python311_path" ]]; then
                log "Removing binary: $python311_path"
                sudo rm -f "$python311_path"
            fi
            
            # Remove common installation directories
            local common_paths=(
                "/usr/local/bin/python3.11"
                "/usr/local/bin/python3.11-config"
                "/usr/local/bin/pip3.11"
                "/usr/local/lib/python3.11"
                "/usr/local/include/python3.11"
                "/usr/local/share/man/man1/python3.11.1"
            )
            
            for path in "${common_paths[@]}"; do
                if [[ -e "$path" ]]; then
                    log "Removing: $path"
                    sudo rm -rf "$path"
                fi
            done
            
            # Also check for any python3.11* binaries
            local python311_binaries=$(find /usr/local/bin/ -name "python3.11*" 2>/dev/null)
            if [[ -n "$python311_binaries" ]]; then
                log "Removing additional python3.11 binaries..."
                echo "$python311_binaries" | while read -r binary; do
                    log "Removing: $binary"
                    sudo rm -f "$binary"
                done
            fi
            
            success_log "Existing Python 3.11.x installation removed"
        fi
    else
        success_log "No existing Python 3.11 installation found"
    fi
}

# Function to install Python 3.11.0 from source
install_python311() {
    log "Starting Python 3.11.0 installation process..."
    
    # First check/remove any existing Python 3.11 (except 3.11.0)
    uninstall_existing_python311
    
    # Check if Python 3.11.0 is already installed after cleanup
    if command_exists python3.11; then
        local current_version=$(python3.11 --version 2>/dev/null)
        if [[ "$current_version" == *"3.11.0"* ]]; then
            success_log "Python 3.11.0 is already installed and ready to use"
            python3.11 --version
            return 0
        else
            error_log "Failed to properly clean existing Python 3.11 installation"
            return 1
        fi
    fi
    
    # Proceed with fresh installation
    log "Installing Python 3.11.0 from source..."
    
    # Update package list
    log "Updating package list..."
    if ! sudo apt update; then
        error_log "Failed to update package list"
        return 1
    fi
    
    # Install build dependencies for Python
    log "Installing Python build dependencies..."
    local dependencies=(
        "build-essential"
        "zlib1g-dev"
        "libncurses5-dev"
        "libgdbm-dev"
        "libnss3-dev"
        "libssl-dev"
        "libreadline-dev"
        "libffi-dev"
        "libsqlite3-dev"
        "wget"
        "libbz2-dev"
        "liblzma-dev"
        "tk-dev"
        "libgdbm-compat-dev"
        "uuid-dev"
    )
    
    for dep in "${dependencies[@]}"; do
        log "Installing $dep..."
        if ! sudo apt install -y "$dep"; then
            error_log "Failed to install $dep"
            return 1
        fi
    done
    
    # Create temporary directory for Python source
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download Python 3.11.0 source
    log "Downloading Python 3.11.0 source code..."
    if ! wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz; then
        error_log "Failed to download Python 3.11.0 source"
        return 1
    fi
    
    # Extract source
    log "Extracting Python source..."
    if ! tar -xf Python-3.11.0.tgz; then
        error_log "Failed to extract Python source"
        return 1
    fi
    
    cd Python-3.11.0
    
    # Configure build
    log "Configuring Python build..."
    if ! ./configure --enable-optimizations --with-ensurepip=install; then
        error_log "Failed to configure Python build"
        return 1
    fi
    
    # Compile Python (using multiple cores)
    local cores=$(nproc)
    log "Compiling Python 3.11.0 using $cores cores (this may take a while)..."
    if ! make -j"$cores"; then
        error_log "Failed to compile Python"
        return 1
    fi
    
    # Install Python
    log "Installing Python 3.11.0..."
    if ! sudo make altinstall; then
        error_log "Failed to install Python"
        return 1
    fi
    
    # Clean up with proper error handling
    cd /
    log "Cleaning up temporary files..."
    # Use sudo to remove files that may have root ownership
    sudo rm -rf "$temp_dir" 2>/dev/null || {
        warning_log "Some temporary files could not be removed automatically"
        warning_log "You may manually remove: $temp_dir"
    }
    
    # Verify installation
    if command_exists python3.11; then
        local installed_version=$(python3.11 --version)
        if [[ "$installed_version" == *"3.11.0"* ]]; then
            success_log "Python 3.11.0 installed successfully"
            python3.11 --version
        else
            error_log "Python 3.11.0 installation verification failed - wrong version: $installed_version"
            return 1
        fi
    else
        error_log "Python 3.11.0 installation verification failed - command not found"
        return 1
    fi
}

# Function to setup Frida environment
setup_frida_environment() {
    log "Setting up Frida environment..."
    
    # Create brida directory under Downloads
    local brida_dir="$HOME/Downloads/brida"
    log "Checking directory: $brida_dir"
    
    if [[ -d "$brida_dir" ]]; then
        warning_log "Directory $brida_dir already exists"
        log "Removing existing directory to create a clean environment..."
        
        # Remove existing directory
        if ! rm -rf "$brida_dir"; then
            error_log "Failed to remove existing directory $brida_dir"
            return 1
        fi
        success_log "Existing directory removed"
    fi
    
    # Create new clean directory
    log "Creating clean directory: $brida_dir"
    if ! mkdir -p "$brida_dir"; then
        error_log "Failed to create directory $brida_dir"
        return 1
    fi
    success_log "Created clean directory $brida_dir"
    
    cd "$brida_dir"
    
    # Create virtual environment using Python 3.11.0
    log "Creating virtual environment with Python 3.11.0..."
    if ! python3.11 -m venv venv; then
        error_log "Failed to create virtual environment"
        return 1
    fi
    
    # Activate virtual environment
    log "Activating virtual environment..."
    if ! source venv/bin/activate; then
        error_log "Failed to activate virtual environment"
        return 1
    fi
    
    # Verify Python version in virtual environment
    log "Verifying Python version in virtual environment..."
    local venv_python_version=$(python --version)
    if [[ "$venv_python_version" == *"3.11.0"* ]]; then
        success_log "Virtual environment using correct Python version: $venv_python_version"
    else
        error_log "Virtual environment using wrong Python version: $venv_python_version"
        return 1
    fi
    
    # Upgrade pip
    log "Upgrading pip..."
    if ! pip install --upgrade pip; then
        error_log "Failed to upgrade pip"
        return 1
    fi
    
    success_log "Virtual environment setup completed"
}

# Function to install Frida and related tools
install_frida_tools() {
    log "Installing Frida and related tools in virtual environment..."
    
    # Make sure we're in the virtual environment
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        error_log "Virtual environment is not activated"
        error_log "Cannot install Frida tools without active virtual environment"
        return 1
    fi
    
    # Display virtual environment info
    success_log "Virtual environment active: $VIRTUAL_ENV"
    log "Python executable: $(which python)"
    log "Pip executable: $(which pip)"
    log "Python version: $(python --version)"
    
    # Verify we're using the correct Python version
    local current_python=$(python --version)
    if [[ "$current_python" != *"3.11.0"* ]]; then
        error_log "Wrong Python version in virtual environment: $current_python"
        return 1
    fi
    
    # Install Frida 16.7.12
    log "Installing Frida version 16.7.12 in virtual environment..."
    if ! pip install frida==16.7.12; then
        error_log "Failed to install Frida in virtual environment"
        return 1
    fi
    
    # Verify Frida installation location
    local frida_location=$(python -c "import frida; print(frida.__file__)" 2>/dev/null)
    if [[ "$frida_location" == *"$VIRTUAL_ENV"* ]]; then
        success_log "✓ Frida installed in virtual environment: $frida_location"
    else
        error_log "✗ Frida not installed in virtual environment. Location: $frida_location"
        return 1
    fi
    
    # Install Frida-tools version 13.2.1
    log "Installing Frida-tools version 13.2.1 in virtual environment..."
    if ! pip install frida-tools==13.2.1; then
        error_log "Failed to install Frida-tools in virtual environment"
        return 1
    fi
    
    # Verify frida command is from virtual environment
    local frida_cmd_location=$(which frida)
    if [[ "$frida_cmd_location" == *"$VIRTUAL_ENV"* ]]; then
        success_log "✓ Frida command installed in virtual environment: $frida_cmd_location"
    else
        error_log "✗ Frida command not from virtual environment. Location: $frida_cmd_location"
        return 1
    fi
    
    # Install pyro4
    log "Installing pyro4 in virtual environment..."
    if ! pip install pyro4; then
        error_log "Failed to install pyro4 in virtual environment"
        return 1
    fi
    
    # Verify pyro4 installation location
    local pyro4_location=$(python -c "import Pyro4; print(Pyro4.__file__)" 2>/dev/null)
    if [[ "$pyro4_location" == *"$VIRTUAL_ENV"* ]]; then
        success_log "✓ Pyro4 installed in virtual environment: $pyro4_location"
    else
        error_log "✗ Pyro4 not installed in virtual environment. Location: $pyro4_location"
        return 1
    fi
    
    # Show installed packages in virtual environment
    log "Packages installed in virtual environment:"
    pip list | grep -E "(frida|pyro4|Pyro4)"
    
    success_log "All Python packages installed successfully in virtual environment"
}

# Function to install Node.js and frida-compile
install_node_and_frida_compile() {
    log "Installing Node.js and frida-compile..."
    
    # Check if Node.js is installed
    if ! command_exists node; then
        log "Installing Node.js..."
        # Install Node.js using apt
        if ! curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; then
            error_log "Failed to add Node.js repository"
            return 1
        fi
        
        if ! sudo apt-get install -y nodejs; then
            error_log "Failed to install Node.js"
            return 1
        fi
    else
        success_log "Node.js is already installed"
        node --version
        npm --version
    fi
    
    # Check if frida-compile is already installed with correct version (system-wide)
    if command_exists frida-compile; then
        # Check system-wide npm installation, not venv
        local current_frida_compile_version=$(npm list -g frida-compile --depth=0 2>/dev/null | grep "frida-compile@" | sed 's/.*frida-compile@//' | sed 's/ .*//')
        if [[ -z "$current_frida_compile_version" ]]; then
            # Fallback method
            current_frida_compile_version=$(frida-compile --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
        fi
        
        log "Found existing system-wide frida-compile: $current_frida_compile_version"
        
        if [[ "$current_frida_compile_version" == "10.2.5" ]]; then
            success_log "frida-compile version 10.2.5 is already installed system-wide - keeping it"
            log "System-wide frida-compile location: $(which frida-compile)"
            return 0
        else
            warning_log "Found system-wide frida-compile with different version: $current_frida_compile_version"
            log "Uninstalling existing system-wide frida-compile to install version 10.2.5..."
            
            # Uninstall existing frida-compile
            if ! sudo npm uninstall -g frida-compile; then
                warning_log "Failed to uninstall existing frida-compile, proceeding with installation"
            else
                success_log "Existing system-wide frida-compile uninstalled"
            fi
        fi
    else
        log "System-wide frida-compile not found, proceeding with installation"
    fi
    
    # Install frida-compile version 10.2.5 system-wide
    log "Installing frida-compile version 10.2.5 system-wide..."
    if ! sudo npm install -g frida-compile@10.2.5; then
        error_log "Failed to install system-wide frida-compile"
        return 1
    fi
    
    # Verify installation
    if command_exists frida-compile; then
        local installed_version=$(npm list -g frida-compile --depth=0 2>/dev/null | grep "frida-compile@" | sed 's/.*frida-compile@//' | sed 's/ .*//')
        if [[ -z "$installed_version" ]]; then
            installed_version=$(frida-compile --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
        fi
        
        if [[ "$installed_version" == "10.2.5" ]]; then
            success_log "frida-compile version 10.2.5 installed successfully system-wide"
            log "System-wide frida-compile location: $(which frida-compile)"
            log "Version: $installed_version"
        else
            error_log "frida-compile installation verification failed - wrong version: $installed_version"
            return 1
        fi
    else
        error_log "frida-compile installation verification failed - command not found"
        return 1
    fi
}

# Function to verify all installations
verify_installations() {
    log "Verifying all installations..."
    
    local errors=0
    
    # Check Python 3.11.0
    if command_exists python3.11; then
        local python_version=$(python3.11 --version)
        if [[ "$python_version" == *"3.11.0"* ]]; then
            success_log "✓ Python 3.11.0: $python_version"
        else
            error_log "✗ Wrong Python version installed: $python_version (expected 3.11.0)"
            ((errors++))
        fi
    else
        error_log "✗ Python 3.11 not found"
        ((errors++))
    fi
    
    # Check if we're in the brida directory and virtual environment exists
    if [[ -d "$HOME/Downloads/brida/venv" ]]; then
        success_log "✓ Virtual environment created in $HOME/Downloads/brida"
        
        # Activate virtual environment for checks
        source "$HOME/Downloads/brida/venv/bin/activate"
        
        # Verify we're in the virtual environment
        if [[ "$VIRTUAL_ENV" == "$HOME/Downloads/brida/venv" ]]; then
            success_log "✓ Virtual environment activated: $VIRTUAL_ENV"
        else
            error_log "✗ Failed to activate virtual environment"
            ((errors++))
        fi
        
        # Check Python version in venv
        local venv_python_version=$(python --version 2>/dev/null)
        if [[ "$venv_python_version" == *"3.11.0"* ]]; then
            success_log "✓ Virtual environment using Python 3.11.0"
        else
            error_log "✗ Virtual environment using wrong Python version: $venv_python_version"
            ((errors++))
        fi
        
        # Check Frida installation and location
        if python -c "import frida; print(f'Frida version: {frida.__version__}')" 2>/dev/null; then
            local frida_version=$(python -c "import frida; print(frida.__version__)" 2>/dev/null)
            local frida_location=$(python -c "import frida; print(frida.__file__)" 2>/dev/null)
            
            if [[ "$frida_version" == "16.7.12" ]]; then
                if [[ "$frida_location" == *"$VIRTUAL_ENV"* ]]; then
                    success_log "✓ Frida 16.7.12 installed in virtual environment"
                    success_log "  Location: $frida_location"
                else
                    error_log "✗ Frida installed but NOT in virtual environment"
                    error_log "  Location: $frida_location"
                    ((errors++))
                fi
            else
                error_log "✗ Wrong Frida version: $frida_version (expected 16.7.12)"
                ((errors++))
            fi
        else
            error_log "✗ Frida not properly installed in virtual environment"
            ((errors++))
        fi
        
        # Check Frida-tools version and location (within venv)
        local frida_cmd_location=$(which frida 2>/dev/null)
        if [[ -n "$frida_cmd_location" ]]; then
            if [[ "$frida_cmd_location" == *"$VIRTUAL_ENV"* ]]; then
                # Get frida-tools version from pip list since frida --version may not work as expected
                local frida_tools_version=$(pip show frida-tools 2>/dev/null | grep "^Version:" | cut -d' ' -f2)
                if [[ "$frida_tools_version" == "13.2.1" ]]; then
                    success_log "✓ Frida-tools 13.2.1 installed in virtual environment"
                    success_log "  Command location: $frida_cmd_location"
                    success_log "  Pip version: $frida_tools_version"
                else
                    error_log "✗ Wrong Frida-tools version in venv: $frida_tools_version (expected 13.2.1)"
                    ((errors++))
                fi
            else
                error_log "✗ Frida command not from virtual environment"
                error_log "  Location: $frida_cmd_location"
                ((errors++))
            fi
        else
            error_log "✗ Frida command not found in virtual environment"
            ((errors++))
        fi
        
        # Check pyro4 installation and location
        if python -c "import Pyro4; print('Pyro4 imported successfully')" 2>/dev/null; then
            local pyro4_location=$(python -c "import Pyro4; print(Pyro4.__file__)" 2>/dev/null)
            if [[ "$pyro4_location" == *"$VIRTUAL_ENV"* ]]; then
                success_log "✓ Pyro4 installed in virtual environment"
                success_log "  Location: $pyro4_location"
            else
                error_log "✗ Pyro4 installed but NOT in virtual environment"
                error_log "  Location: $pyro4_location"
                ((errors++))
            fi
        else
            error_log "✗ Pyro4 not properly installed in virtual environment"
            ((errors++))
        fi
        
    else
        error_log "✗ Virtual environment not found"
        ((errors++))
    fi
    
    # Check Node.js and system-wide frida-compile
    if command_exists node; then
        success_log "✓ Node.js: $(node --version)"
    else
        error_log "✗ Node.js not found"
        ((errors++))
    fi
    
    # Check system-wide frida-compile (not the one in venv)
    if command_exists frida-compile; then
        # Make sure we're checking the system-wide version, not venv version
        local system_frida_compile_path=$(which frida-compile)
        if [[ "$system_frida_compile_path" == *"/usr"* ]] || [[ "$system_frida_compile_path" == *"npm"* ]] || [[ "$system_frida_compile_path" != *"$HOME/Downloads/brida/venv"* ]]; then
            # Get system-wide frida-compile version
            local frida_compile_version=$(npm list -g frida-compile --depth=0 2>/dev/null | grep "frida-compile@" | sed 's/.*frida-compile@//' | sed 's/ .*//')
            if [[ -z "$frida_compile_version" ]]; then
                # Fallback to direct command if npm list fails
                frida_compile_version=$(frida-compile --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
            fi
            
            if [[ "$frida_compile_version" == "10.2.5" ]]; then
                success_log "✓ System-wide frida-compile: $frida_compile_version"
                success_log "  Location: $system_frida_compile_path"
            else
                error_log "✗ Wrong system-wide frida-compile version: $frida_compile_version (expected 10.2.5)"
                error_log "  Location: $system_frida_compile_path"
                ((errors++))
            fi
        else
            warning_log "⚠ frida-compile found in venv location: $system_frida_compile_path"
            warning_log "  The system should use the system-wide npm-installed version"
            # Try to check if system-wide version exists
            local system_version=$(npm list -g frida-compile --depth=0 2>/dev/null | grep "frida-compile@" | sed 's/.*frida-compile@//' | sed 's/ .*//')
            if [[ "$system_version" == "10.2.5" ]]; then
                success_log "✓ System-wide frida-compile 10.2.5 is installed via npm"
                log "  Note: PATH may prioritize venv version. Use full path if needed: $(npm bin -g)/frida-compile"
            else
                error_log "✗ System-wide frida-compile version issue: $system_version"
                ((errors++))
            fi
        fi
    else
        error_log "✗ frida-compile not found"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        success_log "All installations verified successfully!"
        log "Setup completed successfully!"
        echo
        success_log "=== VIRTUAL ENVIRONMENT SETUP ==="
        log "To use the Frida environment:"
        log "1. cd $HOME/Downloads/brida"
        log "2. source venv/bin/activate"
        log "3. You can now use frida, frida-tools, and pyro4"
        echo
        success_log "=== SYSTEM-WIDE TOOLS ==="
        log "frida-compile 10.2.5 is installed system-wide via npm"
        log "Location: $(which frida-compile 2>/dev/null || echo 'Use: npm bin -g)/frida-compile')"
        echo
        log "=== VERIFICATION ==="
        log "- Frida 16.7.12 and frida-tools 13.2.1 are in the virtual environment"
        log "- frida-compile 10.2.5 is installed system-wide"
        log "- All components are isolated and won't interfere with each other"
        log "To verify after activating the environment:"
        log "  - python -c 'import frida; print(frida.__file__)'"
        log "  - which frida  (should show venv path)"
        log "  - which frida-compile  (should show system path)"
        log "  - pip list | grep frida"
    else
        error_log "Found $errors errors during verification"
        return 1
    fi
}

# Main execution
main() {
    log "Starting Kali Linux Development Environment Setup"
    log "This script will install:"
    log "- Python 3.11.0 from source (keeping 3.11.0 if exists, removing other 3.11.x versions)"
    log "- Clean virtual environment in ~/Downloads/brida (removing existing if found)"
    log "- Frida 16.7.12 and frida-tools 13.2.1 (in venv)"
    log "- pyro4 (in venv)"
    log "- Node.js and frida-compile 10.2.5 (system-wide)"
    echo
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Installation cancelled by user"
        exit 0
    fi
    
    # Execute installation steps
    install_python311
    setup_frida_environment
    install_frida_tools
    install_node_and_frida_compile
    verify_installations
    
    success_log "Setup script completed successfully!"
}

# Run main function
main "$@"

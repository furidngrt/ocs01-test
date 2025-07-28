#!/bin/bash

# OCS01 Test Client

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                🚀 OCS01 Test Client Setup                    ║${NC}"
    echo -e "${CYAN}║              Complete Build from Source                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Function to check if git is installed
check_git() {
    if command -v git &> /dev/null; then
        print_success "Git is available"
        return 0
    else
        print_error "Git is not installed"
        return 1
    fi
}

# Function to check if Rust is installed
check_rust() {
    if command -v cargo &> /dev/null; then
        print_success "Rust is already installed"
        return 0
    else
        print_warning "Rust is not installed"
        return 1
    fi
}

# Function to install Rust
install_rust() {
    print_step "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    print_success "Rust installed successfully"
}

# Function to clone repository
clone_repository() {
    print_step "Cloning OCS01 Test repository..."
    
    # Check if directory already exists
    if [ -d "ocs01-test" ]; then
        print_warning "Directory 'ocs01-test' already exists"
        read -p "Remove existing directory and clone fresh? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            rm -rf ocs01-test
            print_info "Removed existing directory"
        else
            print_info "Using existing directory"
            cd ocs01-test
            return 0
        fi
    fi
    
    if git clone https://github.com/octra-labs/ocs01-test.git; then
        print_success "Repository cloned successfully"
        cd ocs01-test
    else
        print_error "Failed to clone repository"
        print_info "Please check your internet connection and try again"
        exit 1
    fi
}

# Function to get user input securely
get_private_key() {
    echo ""
    print_info "Please enter your wallet private key (base64 encoded):"
    print_warning "⚠️  Your private key will be stored locally in wallet.json"
    print_warning "⚠️  Keep this file secure and never share it!"
    echo ""
    read -s -p "Private Key: " PRIVATE_KEY
    echo ""
    
    if [ -z "$PRIVATE_KEY" ]; then
        print_error "Private key cannot be empty!"
        exit 1
    fi
}

# Function to get wallet address
get_wallet_address() {
    echo ""
    print_info "Please enter your wallet address:"
    print_info "Example: oct72upsjWZF6hCg557Wisa9ZApM88zw2rAdN2nbPFWaxGa"
    echo ""
    read -p "Wallet Address: " WALLET_ADDRESS
    echo ""
    
    if [ -z "$WALLET_ADDRESS" ]; then
        print_error "Wallet address cannot be empty!"
        exit 1
    fi
    
    # Basic validation for OCT address
    if [[ ! $WALLET_ADDRESS =~ ^oct[a-zA-Z0-9]{40,}$ ]]; then
        print_warning "Address format looks unusual. OCT addresses typically start with 'oct'"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "Setup cancelled. Please check your address and try again."
            exit 1
        fi
    fi
}

# Function to create wallet.json
create_wallet_file() {
    print_step "Creating wallet configuration..."
    
    cat > wallet.json << EOF
{
  "priv": "$PRIVATE_KEY",
  "addr": "$WALLET_ADDRESS",
  "rpc": "https://octra.network"
}
EOF
    
    # Set restrictive permissions on wallet file
    chmod 600 wallet.json
    print_success "Wallet configuration created (wallet.json)"
}

# Function to setup contract interface
setup_contract_interface() {
    print_step "Setting up contract interface..."
    
    if [ -f "EI/exec_interface.json" ]; then
        cp EI/exec_interface.json .
        print_success "Contract interface copied (exec_interface.json)"
    else
        print_error "Contract interface file not found at EI/exec_interface.json"
        print_info "This might indicate an issue with the repository structure"
        exit 1
    fi
}

# Function to build the project
build_project() {
    print_step "Building the project from source..."
    print_info "This may take several minutes on first build..."
    print_info "Downloading dependencies and compiling..."
    
    if cargo build --release; then
        print_success "Project built successfully!"
        print_info "Binary created at: target/release/ocs01-test"
    else
        print_error "Build failed! Please check the error messages above."
        print_info "Common issues:"
        print_info "• Internet connection required for downloading dependencies"
        print_info "• Ensure you have enough disk space"
        print_info "• Check that Rust is properly installed"
        exit 1
    fi
}

# Function to run the application
run_application() {
    echo ""
    print_success "🎉 Complete setup finished successfully!"
    echo ""
    print_info "Your OCS01 Test Client is ready to use!"
    print_info "Project location: $(pwd)"
    print_info "Files created:"
    echo "   • wallet.json (your wallet configuration)"
    echo "   • exec_interface.json (contract interface)"
    echo "   • target/release/ocs01-test (the application)"
    echo ""
    
    read -p "Would you like to start the application now? (Y/n): " start_now
    if [[ ! $start_now =~ ^[Nn]$ ]]; then
        echo ""
        print_step "Starting OCS01 Test Client..."
        echo ""
        ./target/release/ocs01-test
    else
        echo ""
        print_info "To start the application later, run:"
        echo "   cd $(pwd)"
        echo "   ./target/release/ocs01-test"
        echo ""
        print_info "Make sure to keep wallet.json and exec_interface.json in the same directory!"
    fi
}

# Function to show help
show_help() {
    echo "OCS01 Test Client - Complete Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --skip-rust    Skip Rust installation check"
    echo "  --skip-clone   Skip git clone (use if already in project directory)"
    echo ""
    echo "This script will:"
    echo "  1. Check/install Git and Rust if needed"
    echo "  2. Clone the repository from GitHub"
    echo "  3. Ask for your private key and wallet address"
    echo "  4. Create wallet.json configuration"
    echo "  5. Copy contract interface file"
    echo "  6. Build the project from source"
    echo "  7. Run the application"
    echo ""
    echo "Requirements:"
    echo "  • Internet connection (for git clone, Rust installation, and RPC calls)"
    echo "  • Git (will be checked)"
    echo "  • Your wallet private key (base64 encoded)"
    echo "  • Your wallet address"
    echo ""
    echo "Example usage:"
    echo "  # Complete setup from scratch:"
    echo "  curl -sSL https://raw.githubusercontent.com/octra-labs/ocs01-test/main/easy-setup.sh | bash"
    echo ""
    echo "  # Or download and run:"
    echo "  wget https://raw.githubusercontent.com/octra-labs/ocs01-test/main/easy-setup.sh"
    echo "  chmod +x easy-setup.sh"
    echo "  ./easy-setup.sh"
    echo ""
}

# Main execution
main() {
    # Parse command line arguments
    SKIP_RUST=false
    SKIP_CLONE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --skip-rust)
                SKIP_RUST=true
                shift
                ;;
            --skip-clone)
                SKIP_CLONE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header
    
    print_info "This script will set up the OCS01 Test Client completely from source."
    print_info "It will clone the repository, build the project, and configure everything."
    echo ""
    
    # Step 1: Check Git
    if [ "$SKIP_CLONE" = false ]; then
        if ! check_git; then
            print_error "Git is required to clone the repository"
            print_info "Please install Git first:"
            print_info "• Ubuntu/Debian: sudo apt install git"
            print_info "• CentOS/RHEL: sudo yum install git"
            print_info "• macOS: brew install git"
            exit 1
        fi
    fi
    
    # Step 2: Check/Install Rust
    if [ "$SKIP_RUST" = false ]; then
        if ! check_rust; then
            read -p "Would you like to install Rust now? (Y/n): " install_confirm
            if [[ ! $install_confirm =~ ^[Nn]$ ]]; then
                install_rust
            else
                print_error "Rust is required to build this project"
                print_info "Install Rust manually: https://rustup.rs/"
                exit 1
            fi
        fi
    fi
    
    # Step 3: Clone repository
    if [ "$SKIP_CLONE" = false ]; then
        clone_repository
    else
        # Check if we're in the right directory
        if [ ! -f "Cargo.toml" ] || [ ! -d "EI" ]; then
            print_error "Please run this script from the OCS01 test project root directory"
            print_info "The directory should contain Cargo.toml and EI/ folder"
            print_info "Or run without --skip-clone to clone the repository"
            exit 1
        fi
    fi
    
    # Step 4: Get user credentials
    get_private_key
    get_wallet_address
    
    # Step 5: Create configuration files
    create_wallet_file
    setup_contract_interface
    
    # Step 6: Build project from source
    build_project
    
    # Step 7: Run application
    run_application
}

# Trap to clean up on exit
cleanup() {
    if [ $? -ne 0 ]; then
        echo ""
        print_error "Setup failed! Check the error messages above."
        print_info "You can run this script again to retry."
        print_info "If the repository was cloned, you can also run:"
        print_info "  cd ocs01-test && ./easy-setup.sh --skip-clone"
    fi
}

trap cleanup EXIT

# Run main function
main "$@"

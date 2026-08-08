#!/bin/bash
# Debian 12 to 13 Upgrade Script for Proxmox LXC Containers
# Version: 2.2 - Proper Docker handling
# Date: 2026-08-08

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/debian-upgrade-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Configuration
REQUIRED_SPACE_GB=3
REQUIRED_SPACE_MB=$((REQUIRED_SPACE_GB * 1024))
BACKUP_SOURCES="/etc/apt/sources.list.backup-$(date +%Y%m%d)"
CLEANUP_PERFORMED=false
POST_CLEANUP_PERFORMED=false
DOCKER_INSTALLED=false

# Error handling function
error_exit() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}"
    echo -e "${YELLOW}To rollback to Debian 12, run:${NC}"
    echo "  cp $BACKUP_SOURCES /etc/apt/sources.list"
    echo "  apt update"
    exit 1
}

# Warning function
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Success function
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Info function
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Convert MB to GB for display (bash integer math)
mb_to_gb() {
    local mb=$1
    local gb=$((mb / 1024))
    local remainder=$((mb % 1024))
    if [[ $remainder -gt 0 ]]; then
        echo "${gb}.${remainder:0:2}GB"
    else
        echo "${gb}GB"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

# Check if Docker is installed
check_docker() {
    if command -v docker &>/dev/null || dpkg -l | grep -q "docker.io\|docker-ce\|docker-cli"; then
        DOCKER_INSTALLED=true
        info "Docker detected - will handle gracefully during upgrade"
        
        # Check which Docker packages are installed
        DOCKER_PACKAGES=$(dpkg -l | grep -E "docker" | awk '{print $2}' | tr '\n' ' ')
        info "Installed Docker packages: $DOCKER_PACKAGES"
    fi
}

# Handle Docker packages pre-upgrade
handle_docker_pre_upgrade() {
    if [[ "$DOCKER_INSTALLED" == true ]]; then
        info "Handling Docker packages pre-upgrade..."
        
        # Remove conflicting docker-buildx-plugin if it exists (will be replaced)
        if dpkg -l | grep -q "docker-buildx-plugin"; then
            warning "Removing docker-buildx-plugin (will be replaced by docker-buildx)"
            apt remove -y docker-buildx-plugin 2>/dev/null || true
        fi
        
        # Remove docker-ce-cli if installed (will use docker-cli from Debian)
        if dpkg -l | grep -q "docker-ce-cli"; then
            warning "Removing docker-ce-cli (will use docker-cli from Debian)"
            apt remove -y docker-ce-cli 2>/dev/null || true
        fi
        
        # Remove docker-ce if installed (will use docker.io from Debian)
        if dpkg -l | grep -q "docker-ce"; then
            warning "Removing docker-ce (will use docker.io from Debian)"
            apt remove -y docker-ce 2>/dev/null || true
        fi
        
        # Keep docker.io if installed
        if dpkg -l | grep -q "docker.io"; then
            info "Keeping docker.io package"
        fi
        
        # Keep docker-cli if installed
        if dpkg -l | grep -q "docker-cli"; then
            info "Keeping docker-cli package"
        fi
        
        # Fix any broken packages before upgrade
        apt --fix-broken install -y 2>/dev/null || true
    fi
}

# Handle Docker packages post-upgrade
handle_docker_post_upgrade() {
    if [[ "$DOCKER_INSTALLED" == true ]]; then
        info "Reinstalling Docker packages post-upgrade..."
        
        # Install Docker from Debian 13 repositories
        apt install -y docker.io docker-cli docker-buildx docker-compose-plugin 2>/dev/null || {
            warning "Some Docker packages couldn't be installed from Debian repos"
            warning "You may need to reinstall Docker manually"
        }
        
        # If Docker was using the official repo, re-add it
        if [[ -f /etc/apt/sources.list.d/docker.list.bak ]] || [[ -f /etc/apt/sources.list.d/docker-ce.list.bak ]]; then
            info "Restoring Docker repository..."
            if [[ -f /etc/apt/sources.list.d/docker.list.bak ]]; then
                mv /etc/apt/sources.list.d/docker.list.bak /etc/apt/sources.list.d/docker.list 2>/dev/null || true
            fi
            if [[ -f /etc/apt/sources.list.d/docker-ce.list.bak ]]; then
                mv /etc/apt/sources.list.d/docker-ce.list.bak /etc/apt/sources.list.d/docker-ce.list 2>/dev/null || true
            fi
            
            # Update and install Docker from official repo
            apt update 2>/dev/null || true
            apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || {
                warning "Could not reinstall Docker from official repo"
                warning "You may need to reinstall Docker manually"
            }
        fi
        
        # Start Docker if it's not running
        if systemctl is-active --quiet docker 2>/dev/null; then
            info "Docker is already running"
        else
            info "Starting Docker service..."
            systemctl start docker 2>/dev/null || true
            systemctl enable docker 2>/dev/null || true
        fi
        
        # Check Docker status
        if docker --version &>/dev/null; then
            success "Docker reinstalled successfully: $(docker --version 2>/dev/null)"
        else
            warning "Docker may need manual reinstallation"
        fi
    fi
}

# Check disk space with cleanup option
check_disk_space() {
    info "Checking available disk space..."
    AVAILABLE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
    
    if [[ -z "$AVAILABLE_SPACE" ]]; then
        error_exit "Could not determine available disk space"
    fi
    
    AVAILABLE_GB_DISPLAY=$(mb_to_gb $AVAILABLE_SPACE)
    REQUIRED_GB_DISPLAY="${REQUIRED_SPACE_GB}GB"
    info "Available space: ${AVAILABLE_GB_DISPLAY} (${REQUIRED_GB_DISPLAY} required)"
    
    if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE_MB ]]; then
        warning "Insufficient disk space. Available: ${AVAILABLE_GB_DISPLAY}, Required: ${REQUIRED_GB_DISPLAY}"
        echo ""
        echo -e "${YELLOW}The script can attempt to clean up space by:${NC}"
        echo "  - Removing pnpm/npm/yarn caches"
        echo "  - Cleaning APT cache"
        echo "  - Removing old logs"
        echo "  - Cleaning build caches"
        echo "  - Cleaning Docker (if installed)"
        echo ""
        read -p "Would you like to attempt cleanup to free space? (y/n): " -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            perform_pre_cleanup
            # Re-check space after cleanup
            AVAILABLE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
            AVAILABLE_GB_DISPLAY=$(mb_to_gb $AVAILABLE_SPACE)
            info "Available space after cleanup: ${AVAILABLE_GB_DISPLAY}"
            
            if [[ $AVAILABLE_SPACE -lt $REQUIRED_SPACE_MB ]]; then
                echo -e "${YELLOW}Still insufficient space after cleanup.${NC}"
                echo -e "${YELLOW}Options:${NC}"
                echo "  1. Expand disk from Proxmox: pct resize <CT_ID> rootfs +4G"
                echo "  2. Manually clean more space"
                echo "  3. Abort the upgrade"
                echo ""
                read -p "Continue anyway? (y/n): " -r
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    error_exit "Insufficient disk space. Please free up space and try again."
                else
                    warning "Continuing with low disk space - upgrade may fail!"
                fi
            else
                success "Sufficient space available after cleanup!"
            fi
        else
            echo -e "${YELLOW}Options to free space:${NC}"
            echo "  1. Expand disk from Proxmox: pct resize <CT_ID> rootfs +4G"
            echo "  2. Manually clean: npm cache clean --force"
            echo "  3. Clean logs: journalctl --vacuum-size=100M"
            echo ""
            error_exit "Insufficient disk space. Please free up space and try again."
        fi
    else
        success "Sufficient disk space available: ${AVAILABLE_GB_DISPLAY}"
    fi
}

# Pre-upgrade cleanup (runs when space is low)
perform_pre_cleanup() {
    info "Starting pre-upgrade cleanup to free up space..."
    CLEANUP_PERFORMED=true
    
    local BEFORE_SPACE=$(df -m / | awk 'NR==2 {print $3}')
    
    echo -e "${BLUE}1. Cleaning npm cache...${NC}"
    npm cache clean --force 2>/dev/null || true
    
    echo -e "${BLUE}2. Cleaning yarn cache...${NC}"
    yarn cache clean 2>/dev/null || true
    
    echo -e "${BLUE}3. Cleaning pnpm store cache...${NC}"
    if [[ -d /root/.local/share/pnpm/store ]]; then
        PNPM_SIZE=$(du -sm /root/.local/share/pnpm/store 2>/dev/null | awk '{print $1}' || echo "0")
        rm -rf /root/.local/share/pnpm/store/v10/* 2>/dev/null || true
        rm -rf /root/.local/share/pnpm/store/v9/* 2>/dev/null || true
        rm -rf /root/.local/share/pnpm/store/v8/* 2>/dev/null || true
        echo -e "${GREEN}  Removed ~${PNPM_SIZE}MB from pnpm cache${NC}"
    fi
    
    echo -e "${BLUE}4. Cleaning APT cache...${NC}"
    apt clean 2>/dev/null || true
    apt autoclean 2>/dev/null || true
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    
    echo -e "${BLUE}5. Removing old package lists...${NC}"
    rm -rf /var/lib/apt/lists/* 2>/dev/null || true
    
    echo -e "${BLUE}6. Cleaning journal logs...${NC}"
    journalctl --vacuum-size=100M 2>/dev/null || true
    
    echo -e "${BLUE}7. Removing old rotated logs...${NC}"
    find /var/log -name "*.gz" -delete 2>/dev/null || true
    find /var/log -name "*.1" -delete 2>/dev/null || true
    find /var/log -name "*.old" -delete 2>/dev/null || true
    
    echo -e "${BLUE}8. Cleaning temporary files...${NC}"
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo -e "${BLUE}9. Looking for build caches to clean...${NC}"
    for cache_dir in /opt/*/.next/cache /opt/*/node_modules/.cache /var/www/*/.next/cache /home/*/.next/cache /root/*/.next/cache; do
        if [[ -d "$cache_dir" ]]; then
            CACHE_SIZE=$(du -sm "$cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
            rm -rf "$cache_dir"/* 2>/dev/null || true
            echo -e "${GREEN}  Cleaned ${CACHE_SIZE}MB from $cache_dir${NC}"
        fi
    done
    
    echo -e "${BLUE}10. Cleaning Docker (if installed)...${NC}"
    if command -v docker &>/dev/null; then
        # Clean Docker images, containers, and volumes
        docker system prune -a -f 2>/dev/null || true
        docker volume prune -f 2>/dev/null || true
        docker network prune -f 2>/dev/null || true
        echo -e "${GREEN}  Cleaned Docker resources${NC}"
    fi
    
    if command -v podman &>/dev/null; then
        echo -e "${BLUE}11. Cleaning Podman...${NC}"
        podman system prune -a -f 2>/dev/null || true
    fi
    
    local AFTER_SPACE=$(df -m / | awk 'NR==2 {print $3}')
    FREED_SPACE=$((BEFORE_SPACE - AFTER_SPACE))
    FREED_GB_DISPLAY=$(mb_to_gb $FREED_SPACE)
    
    echo ""
    success "Pre-upgrade cleanup completed! Freed approximately ${FREED_GB_DISPLAY}"
    echo ""
}

# Post-upgrade cleanup (always runs after successful upgrade)
perform_post_cleanup() {
    info "Starting post-upgrade cleanup..."
    POST_CLEANUP_PERFORMED=true
    
    local BEFORE_SPACE=$(df -m / | awk 'NR==2 {print $3}')
    
    echo -e "${BLUE}1. Removing downloaded Debian package files...${NC}"
    DEB_COUNT=$(find /var/cache/apt/archives -name "*.deb" 2>/dev/null | wc -l)
    if [[ $DEB_COUNT -gt 0 ]]; then
        DEB_SIZE=$(du -sm /var/cache/apt/archives 2>/dev/null | awk '{print $1}' || echo "0")
        rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
        echo -e "${GREEN}  Removed ${DEB_COUNT} package files (~${DEB_SIZE}MB)${NC}"
    else
        echo -e "${GREEN}  No package files to remove${NC}"
    fi
    
    echo -e "${BLUE}2. Removing obsolete packages...${NC}"
    OBSOLETE=$(apt autoremove --dry-run 2>/dev/null | grep -c "Remv" || echo "0")
    if [[ $OBSOLETE -gt 0 ]]; then
        apt autoremove -y 2>/dev/null || true
        echo -e "${GREEN}  Removed ${OBSOLETE} obsolete packages${NC}"
    else
        echo -e "${GREEN}  No obsolete packages to remove${NC}"
    fi
    
    echo -e "${BLUE}3. Cleaning APT cache...${NC}"
    apt clean 2>/dev/null || true
    apt autoclean 2>/dev/null || true
    
    echo -e "${BLUE}4. Removing old kernel packages (if any)...${NC}"
    if command -v dpkg &>/dev/null; then
        CURRENT_KERNEL=$(uname -r 2>/dev/null || echo "")
        OLD_KERNELS=$(dpkg -l | grep -E "linux-image-[0-9]" | grep -v "$CURRENT_KERNEL" | awk '{print $2}' || echo "")
        if [[ -n "$OLD_KERNELS" ]]; then
            echo -e "${YELLOW}  Found old kernel packages. Removing...${NC}"
            apt purge -y $OLD_KERNELS 2>/dev/null || true
        fi
    fi
    
    echo -e "${BLUE}5. Removing old log files...${NC}"
    find /var/log -name "*.gz" -delete 2>/dev/null || true
    find /var/log -name "*.1" -delete 2>/dev/null || true
    find /var/log -name "*.old" -delete 2>/dev/null || true
    
    echo -e "${BLUE}6. Cleaning journal logs (keep 7 days)...${NC}"
    journalctl --vacuum-time=7d 2>/dev/null || true
    
    echo -e "${BLUE}7. Removing temporary files...${NC}"
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo -e "${BLUE}8. Removing Python bytecode cache...${NC}"
    find /usr -name "*.pyc" -type f -delete 2>/dev/null || true
    
    echo -e "${BLUE}9. Removing package manager leftovers...${NC}"
    find /etc -name "*.dpkg-old" -delete 2>/dev/null || true
    find /etc -name "*.dpkg-dist" -delete 2>/dev/null || true
    
    local AFTER_SPACE=$(df -m / | awk 'NR==2 {print $3}')
    FREED_SPACE=$((BEFORE_SPACE - AFTER_SPACE))
    FREED_GB_DISPLAY=$(mb_to_gb $FREED_SPACE)
    
    echo ""
    success "Post-upgrade cleanup completed! Freed approximately ${FREED_GB_DISPLAY}"
    echo ""
    
    echo -e "${BLUE}Current disk usage:${NC}"
    df -h /
    echo ""
}

# Backup sources.list
backup_sources() {
    info "Backing up sources.list..."
    cp /etc/apt/sources.list "$BACKUP_SOURCES"
    success "Sources backed up to: $BACKUP_SOURCES"
}

# Check for third-party repositories
check_third_party_repos() {
    info "Checking for third-party repositories..."
    THIRD_PARTY_REPOS=()
    
    if [[ -d /etc/apt/sources.list.d ]]; then
        for repo in /etc/apt/sources.list.d/*.list; do
            if [[ -f "$repo" ]]; then
                if [[ ! "$repo" =~ \.bak$ ]]; then
                    THIRD_PARTY_REPOS+=("$repo")
                    warning "Found third-party repo: $repo"
                fi
            fi
        done
    fi
    
    if [[ ${#THIRD_PARTY_REPOS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Third-party repositories found. They will be temporarily disabled.${NC}"
        echo -e "${YELLOW}Repositories:${NC}"
        printf '%s\n' "${THIRD_PARTY_REPOS[@]}"
    fi
}

# Disable third-party repositories
disable_third_party_repos() {
    info "Disabling third-party repositories..."
    for repo in "${THIRD_PARTY_REPOS[@]}"; do
        mv "$repo" "${repo}.bak" || warning "Could not disable: $repo"
        success "Disabled: $repo"
    done
}

# Enable third-party repositories
enable_third_party_repos() {
    info "Re-enabling third-party repositories..."
    for repo in "${THIRD_PARTY_REPOS[@]}"; do
        if [[ -f "${repo}.bak" ]]; then
            mv "${repo}.bak" "$repo" || warning "Could not re-enable: $repo"
            success "Re-enabled: $repo"
        fi
    done
}

# Update package lists
update_package_lists() {
    info "Updating package lists..."
    apt update || error_exit "Failed to update package lists"
    success "Package lists updated"
}

# Check for current Debian version
check_current_version() {
    info "Checking current Debian version..."
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$VERSION_CODENAME" != "bookworm" ]]; then
            warning "Current version is not Debian 12 (bookworm). Found: $VERSION_CODENAME"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                error_exit "Upgrade cancelled by user"
            fi
        else
            success "Current version: Debian 12 (bookworm)"
        fi
    fi
}

# Update sources to trixie
update_sources() {
    info "Updating sources from bookworm to trixie..."
    sed -i 's/bookworm/trixie/g' /etc/apt/sources.list || error_exit "Failed to update sources.list"
    success "Sources updated to trixie"
}

# Check upgrade size
check_upgrade_size() {
    info "Checking upgrade size requirements..."
    apt update || error_exit "Failed to update package lists"
    
    UPGRADE_INFO=$(apt full-upgrade --dry-run 2>/dev/null | grep -E "Need to get|After this operation" || echo "")
    
    if [[ -n "$UPGRADE_INFO" ]]; then
        echo -e "${BLUE}Upgrade size information:${NC}"
        echo "$UPGRADE_INFO"
        
        DOWNLOAD_SIZE=$(echo "$UPGRADE_INFO" | grep "Need to get" | awk '{print $4, $5}' || echo "")
        if [[ -n "$DOWNLOAD_SIZE" ]]; then
            info "Download size: $DOWNLOAD_SIZE"
        fi
    else
        warning "Could not determine upgrade size"
    fi
    
    echo -e "${YELLOW}Proceed with upgrade? (y/n):${NC} "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        error_exit "Upgrade cancelled by user"
    fi
}

# Perform minimal upgrade
perform_minimal_upgrade() {
    info "Performing minimal upgrade (without new packages)..."
    apt upgrade --without-new-pkgs -y || error_exit "Minimal upgrade failed"
    success "Minimal upgrade completed"
}

# Perform full distribution upgrade
perform_full_upgrade() {
    info "Performing full distribution upgrade..."
    
    # First, handle Docker pre-upgrade
    handle_docker_pre_upgrade
    
    # Now run the full upgrade
    apt full-upgrade -y || {
        warning "Full upgrade had issues. Attempting to fix..."
        apt --fix-broken install -y
        apt full-upgrade -y || error_exit "Full distribution upgrade failed"
    }
    
    success "Full distribution upgrade completed"
}

# Verify upgrade
verify_upgrade() {
    info "Verifying upgrade..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$VERSION_CODENAME" == "trixie" ]]; then
            success "✅ Upgrade successful! Running Debian 13 (trixie)"
            echo -e "${GREEN}Version: $PRETTY_NAME${NC}"
        else
            warning "Version check shows: $VERSION_CODENAME"
            warning "Upgrade may not have completed successfully"
        fi
    fi
    
    apt --fix-broken install --dry-run | grep -q "0 upgraded, 0 newly installed" || warning "Possible broken packages detected"
}

# Main upgrade function
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Debian 12 → 13 Upgrade Script${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    check_root
    check_docker
    check_current_version
    check_disk_space
    
    backup_sources
    check_third_party_repos
    
    if [[ ${#THIRD_PARTY_REPOS[@]} -gt 0 ]]; then
        disable_third_party_repos
    fi
    
    update_package_lists
    update_sources
    check_upgrade_size
    
    perform_minimal_upgrade
    perform_full_upgrade
    
    # Handle Docker post-upgrade
    handle_docker_post_upgrade
    
    verify_upgrade
    perform_post_cleanup
    
    if [[ ${#THIRD_PARTY_REPOS[@]} -gt 0 ]]; then
        enable_third_party_repos
        update_package_lists
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Upgrade Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Log file: $LOG_FILE"
    echo -e "Sources backup: $BACKUP_SOURCES"
    
    if [[ "$CLEANUP_PERFORMED" == true ]]; then
        echo -e "${YELLOW}Pre-upgrade cleanup was performed to free up space.${NC}"
    fi
    if [[ "$POST_CLEANUP_PERFORMED" == true ]]; then
        echo -e "${GREEN}Post-upgrade cleanup was performed to remove upgrade artifacts.${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}It's recommended to reboot the container:${NC}"
    echo "  reboot"
    echo ""
    echo -e "${YELLOW}After reboot, verify the upgrade with:${NC}"
    echo "  cat /etc/os-release"
    echo ""
    echo -e "${YELLOW}Check that your applications are running:${NC}"
    echo "  # List all running services"
    echo "  systemctl --type=service --state=running"
    echo "  # Or check specific services with:"
    echo "  systemctl status <service-name>"
    echo ""
    if [[ "$DOCKER_INSTALLED" == true ]]; then
        echo -e "${YELLOW}Verify Docker is working:${NC}"
        echo "  docker --version"
        echo "  docker ps"
        echo ""
    fi
    echo -e "${GREEN}Available disk space after upgrade and cleanup:${NC}"
    df -h /
}

# Run main function with trap for error handling
trap 'error_exit "Script interrupted"' INT TERM
main "$@"

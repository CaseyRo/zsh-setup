# shellcheck shell=bash
# ============================================================================
# Network Mounts Configuration
# ============================================================================
# Configures NFS and other network mounts in /etc/fstab

# NFS mount configuration
NFS_SERVER="192.168.1.9"
NFS_EXPORT="/export"
NFS_MOUNT_POINT="/mnt"
NFS_OPTIONS="nfs auto 0 0"

configure_nfs_mount() {
    # Skip on macOS (uses different mount system)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        return 0
    fi

    # Skip if nfs-common not installed
    if ! dpkg -s nfs-common &>/dev/null; then
        return 0
    fi

    print_section "Network Mounts"

    local fstab_entry="${NFS_SERVER}:${NFS_EXPORT} ${NFS_MOUNT_POINT}    ${NFS_OPTIONS}"

    # Check if entry already exists in fstab
    if grep -q "${NFS_SERVER}:${NFS_EXPORT}" /etc/fstab 2>/dev/null; then
        print_skip "NFS mount (already in fstab)"
        track_skipped "NFS mount"
    else
        if ui_confirm "Add NFS mount ${NFS_SERVER}:${NFS_EXPORT} to ${NFS_MOUNT_POINT}?"; then
            print_step "Adding NFS mount to /etc/fstab"

            # Create mount point if it doesn't exist
            if [[ ! -d "$NFS_MOUNT_POINT" ]]; then
                sudo mkdir -p "$NFS_MOUNT_POINT"
            fi

            # Add entry to fstab
            echo "$fstab_entry" | sudo tee -a /etc/fstab >/dev/null

            if grep -q "${NFS_SERVER}:${NFS_EXPORT}" /etc/fstab; then
                print_success "NFS mount added to fstab"
                track_installed "NFS mount"

                # Try to mount
                print_step "Mounting NFS share"
                if sudo mount "$NFS_MOUNT_POINT" 2>/dev/null; then
                    print_success "NFS share mounted at ${NFS_MOUNT_POINT}"
                else
                    print_warning "Could not mount now (server may be unreachable)"
                    print_info "Will auto-mount on next boot when server is available"
                fi
            else
                print_error "Failed to add NFS mount to fstab"
                track_failed "NFS mount"
            fi
        else
            print_info "Skipping NFS mount configuration"
        fi
    fi
}

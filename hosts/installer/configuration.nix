# Minimal NixOS installer ISO with automated deployment.
#
# The flake source is baked into the ISO at /etc/nix-config.
# After booting, run `sudo deploy-config` which will:
#   1. Let you select a target disk and partition it
#   2. Let you pick a host configuration
#   3. Set a password for the user and root
#   4. Install NixOS with your config -- ready on first boot
#
# Build with: just iso
{
  pkgs,
  self,
  ...
}:
let
  deploy-config = pkgs.writeShellScriptBin "deploy-config" ''
    set -euo pipefail

    CONFIG_DIR="/etc/nix-config"
    MNT="/mnt"
    TARGET_USER="dirk"

    # -- Check root --------------------------------------------------------
    if [ "$(id -u)" -ne 0 ]; then
      echo "Error: must run as root (use sudo)"
      exit 1
    fi

    echo ""
    echo "  NixOS Configuration Installer"
    echo "  ============================="
    echo ""

    # -- Select target disk ------------------------------------------------
    echo "Select target disk"
    echo ""

    DISKS=()
    while IFS= read -r line; do
      DISKS+=("$line")
    done < <(lsblk -dnpo NAME,SIZE,MODEL --exclude 7,11 | grep -v "loop\|sr[0-9]\|ram[0-9]")

    if [ "''${#DISKS[@]}" -eq 0 ]; then
      echo "Error: no disks found"
      exit 1
    fi

    for i in "''${!DISKS[@]}"; do
      printf "  %d) %s\n" "$((i + 1))" "''${DISKS[$i]}"
    done
    echo ""

    while true; do
      printf "Select a disk [1-%d]: " "''${#DISKS[@]}"
      read -r choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "''${#DISKS[@]}" ]; then
        DISK="$(echo "''${DISKS[$((choice - 1))]}" | awk '{print $1}')"
        break
      fi
      echo "Invalid choice, try again."
    done

    echo ""
    echo "WARNING: This will ERASE ALL DATA on $DISK"
    printf "Type 'yes' to confirm: "
    read -r confirm
    [ "$confirm" = "yes" ] || { echo "Aborted."; exit 1; }

    # -- Select configuration ----------------------------------------------
    echo ""
    echo "Select a configuration"
    echo ""

    HOSTS=()
    for dir in "$CONFIG_DIR"/hosts/*/; do
      name="$(basename "$dir")"
      [ "$name" = "installer" ] && continue
      [ "$name" = "hpc" ] && continue
      HOSTS+=("$name")
    done

    if [ "''${#HOSTS[@]}" -eq 0 ]; then
      echo "Error: no host configurations found"
      exit 1
    fi

    for i in "''${!HOSTS[@]}"; do
      printf "  %d) %s\n" "$((i + 1))" "''${HOSTS[$i]}"
    done
    echo ""

    while true; do
      printf "Select a configuration [1-%d]: " "''${#HOSTS[@]}"
      read -r choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "''${#HOSTS[@]}" ]; then
        HOSTNAME="''${HOSTS[$((choice - 1))]}"
        break
      fi
      echo "Invalid choice, try again."
    done

    # -- Set password ------------------------------------------------------
    echo ""
    echo "Set password (used for both $TARGET_USER and root)"
    echo ""
    while true; do
      printf "Password: "
      read -rs PASSWORD
      echo ""
      printf "Confirm:  "
      read -rs PASSWORD_CONFIRM
      echo ""
      if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
        if [ -z "$PASSWORD" ]; then
          echo "Password cannot be empty, try again."
        else
          break
        fi
      else
        echo "Passwords do not match, try again."
      fi
      echo ""
    done

    # -- Confirm -----------------------------------------------------------
    DEST="$MNT/home/$TARGET_USER/nix"
    echo ""
    echo "  Disk:           $DISK"
    echo "  Configuration:  $HOSTNAME"
    echo "  User:           Dirk Vanden Boer ($TARGET_USER)"
    echo "  Config dest:    $DEST"
    echo ""
    echo "  Partition layout:"
    echo "    1) 1G   EFI  (FAT32)  label: NIXBOOT"
    echo "    2) rest Root (ext4)   label: NIXROOT"
    echo "    3) 32G  Swap          label: SWAP"
    echo ""
    printf "Proceed with installation? [y/N]: "
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] || { echo "Aborted."; exit 1; }

    # -- Partition ---------------------------------------------------------
    echo ""
    echo ">>> Partitioning $DISK ..."

    # Wipe existing partition table
    ${pkgs.util-linux}/bin/wipefs -af "$DISK"

    # Create GPT partition table
    ${pkgs.gptfdisk}/bin/sgdisk --zap-all "$DISK"

    # Partition 1: 1G EFI
    ${pkgs.gptfdisk}/bin/sgdisk -n 1:0:+1G -t 1:ef00 -c 1:NIXBOOT "$DISK"
    # Partition 3: 32G swap (create before root so root gets the rest)
    ${pkgs.gptfdisk}/bin/sgdisk -n 3:-32G:0 -t 3:8200 -c 3:SWAP "$DISK"
    # Partition 2: rest for root
    ${pkgs.gptfdisk}/bin/sgdisk -n 2:0:0 -t 2:8300 -c 2:NIXROOT "$DISK"

    # Re-read partition table
    sleep 1
    ${pkgs.util-linux}/bin/partprobe "$DISK" 2>/dev/null || true
    sleep 1

    # Determine partition device names (handles nvme vs sda naming)
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
      PART1="''${DISK}p1"
      PART2="''${DISK}p2"
      PART3="''${DISK}p3"
    else
      PART1="''${DISK}1"
      PART2="''${DISK}2"
      PART3="''${DISK}3"
    fi

    # -- Format ------------------------------------------------------------
    echo ">>> Formatting partitions ..."

    ${pkgs.dosfstools}/bin/mkfs.fat -F 32 -n NIXBOOT "$PART1"
    ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L NIXROOT -F "$PART2"
    ${pkgs.util-linux}/bin/mkswap -L SWAP "$PART3"

    # -- Mount -------------------------------------------------------------
    echo ">>> Mounting partitions ..."

    mount "$PART2" "$MNT"
    mkdir -p "$MNT/boot"
    mount "$PART1" "$MNT/boot"
    swapon "$PART3"

    # -- Generate hardware config ------------------------------------------
    echo ">>> Generating hardware configuration ..."
    nixos-generate-config --root "$MNT"

    # -- Copy config to target ---------------------------------------------
    echo ">>> Copying nix config to $DEST ..."
    mkdir -p "$DEST"
    cp -rT "$CONFIG_DIR" "$DEST"
    chmod -R u+w "$DEST"

    # Place the generated hardware-configuration.nix into the host dir
    if [ -f "$MNT/etc/nixos/hardware-configuration.nix" ]; then
      cp "$MNT/etc/nixos/hardware-configuration.nix" "$DEST/hosts/$HOSTNAME/hardware-configuration.nix"
      echo "    Placed generated hardware-configuration.nix in hosts/$HOSTNAME/"
    fi

    # -- Initialize git repo (flake needs it) -----------------------------
    echo ">>> Initializing git repository ..."
    ${pkgs.git}/bin/git -C "$DEST" init -q
    ${pkgs.git}/bin/git -C "$DEST" add -A
    ${pkgs.git}/bin/git -C "$DEST" \
      -c user.name="installer" -c user.email="installer@localhost" \
      commit -qm "Initial config from installer ISO"

    # -- Install -----------------------------------------------------------
    echo ""
    echo ">>> Installing NixOS with configuration '$HOSTNAME' ..."
    echo "    (this will take a while)"
    echo ""
    nixos-install --flake "$DEST#$HOSTNAME" --no-root-password |& ${pkgs.nix-output-monitor}/bin/nom

    # -- Set passwords -----------------------------------------------------
    echo ">>> Setting passwords for $TARGET_USER and root ..."
    echo "$TARGET_USER:$PASSWORD" | chpasswd -R "$MNT"
    echo "root:$PASSWORD" | chpasswd -R "$MNT"

    # -- Deploy encrypted files ---------------------------------------------
    KEYFILE_ENC="$CONFIG_DIR/hosts/installer/desktop.key.enc"
    KEYFILE_DEST="$MNT/home/$TARGET_USER/.local/share/desktop.key"
    AGEKEYS_ENC="$CONFIG_DIR/hosts/installer/age-keys.txt.enc"
    AGEKEYS_DEST="$MNT/home/$TARGET_USER/.config/sops/age/keys.txt"

    if [ -f "$KEYFILE_ENC" ] || [ -f "$AGEKEYS_ENC" ]; then
      echo ">>> Decrypting encrypted files ..."
      printf "Decryption password: "
      read -rs DECRYPT_PASS
      echo ""

      if [ -f "$KEYFILE_ENC" ]; then
        mkdir -p "$(dirname "$KEYFILE_DEST")"
        openssl enc -d -aes-256-cbc -pbkdf2 -pass "pass:$DECRYPT_PASS" -in "$KEYFILE_ENC" -out "$KEYFILE_DEST"
        chmod 600 "$KEYFILE_DEST"
        echo "    Deployed desktop.key"
      fi

      if [ -f "$AGEKEYS_ENC" ]; then
        mkdir -p "$(dirname "$AGEKEYS_DEST")"
        openssl enc -d -aes-256-cbc -pbkdf2 -pass "pass:$DECRYPT_PASS" -in "$AGEKEYS_ENC" -out "$AGEKEYS_DEST"
        chmod 600 "$AGEKEYS_DEST"
        echo "    Deployed age keys"
      fi
    else
      echo ">>> Note: no encrypted files found in ISO, skipping key deployment."
    fi

    # -- Fix ownership -----------------------------------------------------
    if grep -q "^$TARGET_USER:" "$MNT/etc/passwd"; then
      TARGET_UID=$(grep "^$TARGET_USER:" "$MNT/etc/passwd" | cut -d: -f3)
      TARGET_GID=$(grep "^$TARGET_USER:" "$MNT/etc/passwd" | cut -d: -f4)
      echo ">>> Fixing ownership of $DEST to $TARGET_USER ($TARGET_UID:$TARGET_GID) ..."
      chown -R "$TARGET_UID:$TARGET_GID" "$DEST"
    else
      echo ">>> Warning: user '$TARGET_USER' not found in target passwd."
      echo "    After first boot, run: sudo chown -R $TARGET_USER: ~/nix"
    fi

    echo ""
    echo "  Installation complete!"
    echo "  ====================="
    echo ""
    echo "  Your system is fully configured."
    echo "  Reboot and enjoy your new NixOS!"
    echo ""
    echo "  Your nix config lives at: ~/nix"
    echo "  Future updates:  cd ~/nix && sudo nixos-rebuild switch --flake .#$HOSTNAME"
    echo ""
  '';
in
{
  # Bake the flake source into the ISO
  environment.etc."nix-config".source = self;

  environment.systemPackages = with pkgs; [
    deploy-config
    nh
    nix-output-monitor
    openssl
    # Partition & filesystem tools
    parted
    gptfdisk
    dosfstools
    e2fsprogs
    cryptsetup
    # General tools
    git
    vim
    htop
    rsync
    curl
    wget
    jq
    tmux
  ];

  # Enable SSH so you can connect remotely during install
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Allow passwordless sudo (default for installer, but be explicit)
  security.sudo.wheelNeedsPassword = false;

  # Silence ZFS warning (not using ZFS)
  boot.zfs.forceImportRoot = false;

  # Launch deploy-config automatically on root login
  programs.bash.loginShellInit = ''
    if [ "$(id -u)" -eq 0 ] && [ -z "$DEPLOY_CONFIG_DONE" ]; then
      export DEPLOY_CONFIG_DONE=1
      deploy-config
    fi
  '';

  # Enable flakes in the live environment
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}

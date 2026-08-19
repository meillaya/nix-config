# Verification — Why an on-disk `/run` extra-file is unavailable

nixpkgs_source=/nix/store/w8w3fia26p35xays42lixahnzigsl8dv-source
nixos_anywhere_source=/nix/store/bgdvalr7cyy8sg8qv53hklzbcdfzp0h1-source
local_run_fstype=tmpfs

## nixos-anywhere copies extra files before nixos-install
   876	  if [[ -n ${extraFiles} ]]; then
   877	    step Copying extra files
   878	    tar -C "$extraFiles" -cpf- . | runSsh "tar -C /mnt -xf- --no-same-owner"
   879	
   880	    runSsh "chmod 755 /mnt" # tar also changes permissions of /mnt
   881	  fi
   882	
   883	  if [[ ${#extraFilesOwnership[@]} -gt 0 ]]; then
   884	    # shellcheck disable=SC2016
   885	    printf "%s\n" "${!extraFilesOwnership[@]}" "${extraFilesOwnership[@]}" | pr -2t | runSsh 'while read file ownership; do chown -R "$ownership" "/mnt/$file"; done'
   886	  fi
   887	
   888	  step Installing NixOS
   889	  runSsh sh <<SSH
   890	set -eu ${enableDebug}
   891	# when running not in nixos we might miss this directory, but it's needed in the nixos chroot during installation
   892	export PATH="\$PATH:/run/current-system/sw/bin"
   893	
   894	if [ ! -d "/mnt/tmp" ]; then
   895	  # needed for installation if initrd-secrets are used
   896	  mkdir -p /mnt/tmp
   897	  chmod 777 /mnt/tmp
   898	fi
   899	
   900	if [ ${copyHostKeys-n} = "y" ]; then
   901	  # NB we copy host keys that are in turn copied by kexec installer.
   902	  mkdir -m 755 -p /mnt/etc/ssh
   903	  for p in /etc/ssh/ssh_host_*; do
   904	    # Skip if the source file does not exist (i.e. glob did not match any files)
   905	    # or the destination already exists (e.g. copied with --extra-files).
   906	    if [ ! -e "\$p" ] || [ -e "/mnt/\$p" ]; then
   907	      continue
   908	    fi
   909	    cp -a "\$p" "/mnt/\$p"
   910	  done
   911	fi
   912	# https://stackoverflow.com/a/13864829
   913	if [ ! -z ${NIXOS_NO_CHECK+0} ]; then
   914	  export NIXOS_NO_CHECK
   915	fi
   916	nixos-install --no-root-passwd --no-channel-copy --system "$nixosSystem"
   917	SSH

## nixos-install uses boot action
   302	# Switch to the new system configuration.  This will install Grub with
   303	# a menu default pointing at the kernel/initrd/etc of the new
   304	# configuration.
   305	if [[ -z $noBootLoader ]]; then
   306	    echo "installing the boot loader..."
   307	    # Grub needs an mtab.
   308	    ln -sfn /proc/mounts "$mountPoint"/etc/mtab
   309	    export mountPoint
   310	    NIXOS_INSTALL_BOOTLOADER=1 nixos-enter --root "$mountPoint" -c "$(cat <<'EOF'
   311	      set -e
   312	      # Clear the cache for executable locations. They were invalidated by the chroot.
   313	      hash -r
   314	      # Create a bind mount for each of the mount points inside the target file
   315	      # system. This preserves the validity of their absolute paths after changing
   316	      # the root with `nixos-enter`.
   317	      # Without this the bootloader installation may fail due to options that
   318	      # contain paths referenced during evaluation, like initrd.secrets.
   319	      # when not root, re-execute the script in an unshared namespace
   320	      mount --rbind --mkdir / "$mountPoint"
   321	      mount --make-rslave "$mountPoint"
   322	      /run/current-system/bin/switch-to-configuration boot
   323	      umount -R "$mountPoint" && (rmdir "$mountPoint" 2>/dev/null || true)
   324	EOF
   325	)"
   326	fi

## NixOS declares /run tmpfs
   575	        ];
   576	      };
   577	      "/run" = {
   578	        fsType = "tmpfs";
   579	        options = [
   580	          "nosuid"
   581	          "nodev"
   582	          "strictatime"
   583	          "mode=755"
   584	          "size=${config.boot.runSize}"
   585	        ];
   586	      };
   587	      "/dev" = {
   588	        fsType = "devtmpfs";

## first stage moves runtime /run over target root
   654	
   655	
   656	# Start stage 2.  `switch_root' deletes all files in the ramfs on the
   657	# current root.  The path has to be valid in the chroot not outside.
   658	if [ ! -e "$targetRoot/$stage2Init" ]; then
   659	    stage2Check=${stage2Init}
   660	    while [ "$stage2Check" != "${stage2Check%/*}" ] && [ ! -L "$targetRoot/$stage2Check" ]; do
   661	        stage2Check=${stage2Check%/*}
   662	    done
   663	    if [ ! -L "$targetRoot/$stage2Check" ]; then
   664	        echo "stage 2 init script ($targetRoot/$stage2Init) not found"
   665	        fail
   666	    fi
   667	fi
   668	
   669	mkdir -m 0755 -p $targetRoot/proc $targetRoot/sys $targetRoot/dev $targetRoot/run
   670	
   671	mount --move /proc $targetRoot/proc
   672	mount --move /sys $targetRoot/sys
   673	mount --move /dev $targetRoot/dev
   674	mount --move /run $targetRoot/run
   675	
   676	exec env -i $(type -P switch_root) "$targetRoot" "$stage2Init"
   677	
   678	fail # should never be reached

## stage2 activation occurs after that handoff
   130	fi
   131	install -m 01777 -d /tmp
   132	
   133	
   134	# Run the script that performs all configuration activation that does
   135	# not have to be done at boot time.
   136	echo "running activation script..."
   137	$systemConfig/activate
   138	
   139	
   140	# Record the boot configuration.
   141	ln -sfn "$systemConfig" /run/booted-system
   142	
   143	
   144	# Run any user-specified commands.

## users activation reads file only if it exists then
   239	    }
   240	
   241	    if (defined $u->{hashedPasswordFile}) {
   242	        if (-e $u->{hashedPasswordFile}) {
   243	            $u->{hashedPassword} = read_file($u->{hashedPasswordFile});
   244	            chomp $u->{hashedPassword};
   245	        } else {
   246	            warn "warning: password file ‘$u->{hashedPasswordFile}’ does not exist\n";
   247	        }
   248	    } elsif (defined $u->{password}) {
   249	        $u->{hashedPassword} = hashPassword($u->{password});
   250	    }
   251	

## nixos-anywhere integration proves /var/lib persistence
    28	          return machine
    29	      start_all()
    30	      installer.succeed("mkdir -p /tmp/extra-files/var/lib/secrets")
    31	      installer.succeed("echo value > /tmp/extra-files/var/lib/secrets/key")
    32	      installer.succeed("mkdir -p /tmp/extra-files/home/user/.ssh")
    33	      installer.succeed("echo secretkey > /tmp/extra-files/home/user/.ssh/id_ed25519")
    34	      installer.succeed("echo publickey > /tmp/extra-files/home/user/.ssh/id_ed25519.pub")
    35	      installer.succeed("chmod 600 /tmp/extra-files/home/user/.ssh/id_ed25519")
    36	      ssh_key_path = "/etc/ssh/ssh_host_ed25519_key.pub"
    37	      ssh_key_output = installer.wait_until_succeeds(f"""
    38	        ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    39	          root@installed cat {ssh_key_path}
    40	      """)
    41	      installer.succeed("""
    42	        nixos-anywhere \
    43	          -i /root/.ssh/install_key \
    44	          --debug \
    45	          --kexec /etc/nixos-anywhere/kexec-installer.tar.gz \
    46	          --extra-files /tmp/extra-files \
    47	          --store-paths /etc/nixos-anywhere/disko /etc/nixos-anywhere/system-to-install \
    48	          --chown /home/user 1000:100 \
    49	          --copy-host-keys \
    50	          root@installed >&2
    51	      """)
    52	      try:
    53	        installed.shutdown()
    54	      except BrokenPipeError:
    55	        # qemu has already exited
    56	        pass
    57	      new_machine = create_test_machine(oldmachine=installed, name="after_install")
    58	      new_machine.start()
    59	      hostname = new_machine.succeed("hostname").strip()
    60	      assert "nixos-anywhere" == hostname, f"'nixos-anywhere' != '{hostname}'"
    61	      content = new_machine.succeed("cat /var/lib/secrets/key").strip()
    62	      assert "value" == content, f"secret does not have expected value: {content}"
    63	      ssh_key_content = new_machine.succeed(f"cat {ssh_key_path}").strip()
    64	      assert ssh_key_content in ssh_key_output, "SSH host identity changed"

run_path_chain=PASS

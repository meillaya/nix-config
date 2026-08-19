function install_with_bootstrap_password
    set runtime "$XDG_RUNTIME_DIR"
    test -n "$runtime"; or return 1
    findmnt -no FSTYPE --target "$runtime" | string match -qr '^tmpfs$'; or return 1

    set stage (mktemp -d "$runtime/nixos-extra.XXXXXXXX"); or return 1
    function __cleanup_nixos_password_stage --inherit-variable stage
        command rm -rf -- "$stage"
        functions --erase __cleanup_nixos_password_exit \
          __cleanup_nixos_password_hup __cleanup_nixos_password_int \
          __cleanup_nixos_password_term __cleanup_nixos_password_stage \
          install_with_bootstrap_password
    end
    function __cleanup_nixos_password_exit --on-event fish_exit --inherit-variable stage
        command rm -rf -- "$stage"
    end
    function __cleanup_nixos_password_hup --on-signal HUP
        __cleanup_nixos_password_stage
        exit 129
    end
    function __cleanup_nixos_password_int --on-signal INT
        __cleanup_nixos_password_stage
        exit 130
    end
    function __cleanup_nixos_password_term --on-signal TERM
        __cleanup_nixos_password_stage
        exit 143
    end

    command install -d -m 700 "$stage/var/lib/nixos-bootstrap"; or begin
        __cleanup_nixos_password_stage
        return 1
    end

    # Prompts privately on the controlling terminal; stdout goes directly to the file.
    nix shell nixpkgs#mkpasswd --command mkpasswd --method=yescrypt \
      > "$stage/var/lib/nixos-bootstrap/mei-password.hash"; or begin
        __cleanup_nixos_password_stage
        return 1
    end
    command chmod 600 "$stage/var/lib/nixos-bootstrap/mei-password.hash"; or begin
        __cleanup_nixos_password_stage
        return 1
    end

    test (command tail -c 1 "$stage/var/lib/nixos-bootstrap/mei-password.hash" \
      | command od -An -tuC | string trim) = 10; and \
    test (command wc -l < "$stage/var/lib/nixos-bootstrap/mei-password.hash" \
      | string trim) -eq 1; and \
    command grep -Eqx '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{0,86}\$[./A-Za-z0-9]{43}$' \
      "$stage/var/lib/nixos-bootstrap/mei-password.hash"; or begin
        __cleanup_nixos_password_stage
        return 1
    end

    nix run github:nix-community/nixos-anywhere -- \
      --flake ".#x86_64-linux" \
      --target-host "root@$TARGET" \
      --build-on local \
      --extra-files "$stage" \
      --option max-jobs 1 \
      --option cores 1

    set rc $status
    __cleanup_nixos_password_stage
    return $rc
end

install_with_bootstrap_password

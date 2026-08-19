set stage $argv[1]
mkdir -p "$stage"
function __cleanup_nixos_password_stage --inherit-variable stage
    command rm -rf -- "$stage"
    functions --erase __cleanup_nixos_password_exit \
      __cleanup_nixos_password_hup __cleanup_nixos_password_int \
      __cleanup_nixos_password_term __cleanup_nixos_password_stage
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
while true
    sleep 1
end

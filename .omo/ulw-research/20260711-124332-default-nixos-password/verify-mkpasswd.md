# Verification — mkpasswd yescrypt availability

Command: `nix shell nixpkgs#mkpasswd --command mkpasswd --method=help`

Exit status: 0

```text
unpacking 'https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1' into the Git cache...
Available methods:
yescrypt        Yescrypt
scrypt          scrypt
bcrypt          bcrypt
bcrypt_a        bcrypt (obsolete $2a$ version)
sha512crypt     SHA-512
sha256crypt     SHA-256
sunmd5          SunMD5
md5crypt        MD5
bsdicrypt       BSDI extended DES-based crypt(3)
descrypt        standard 56 bit DES-based crypt(3)
sm3crypt        ShangMi 3
sm3_yescrypt    ShangMi 3 Yescrypt
gost_yescrypt   GOST Yescrypt
nt              NT-Hash
```

Verdict: PASS; the exact package/workflow command exposes `yescrypt` as a supported method without generating or recording a password.

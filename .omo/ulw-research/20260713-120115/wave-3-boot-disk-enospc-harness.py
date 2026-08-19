#!/usr/bin/env python3
"""Research-only control-flow probe against the exact pinned NixOS builder."""
from __future__ import annotations

import errno
import sys
import tempfile
import types
from pathlib import Path
from typing import Any

SOURCE = Path('/nix/store/ybsdbv9rq4zdhh11sa6qalq5b2b602kb-systemd-boot/bin/systemd-boot')
text = SOURCE.read_text()
module = types.ModuleType('pinned_systemd_boot_builder_probe')
sys.modules[module.__name__] = module
ns: dict[str, Any] = module.__dict__
exec(compile(text, str(SOURCE), 'exec'), ns)
BootFile = ns['BootFile']
CopyWriter = ns['CopyWriter']
garbage_collect = ns['garbage_collect']
write_boot_files = ns['write_boot_files']
shutil = ns['shutil']


def run_case(name: str, keep_old: bool) -> None:
    with tempfile.TemporaryDirectory(prefix=f'{name}-') as td:
        root = Path(td)
        boot = root / 'boot'
        nixos = boot / 'EFI/nixos'
        entries = boot / 'loader/entries'
        nixos.mkdir(parents=True)
        entries.mkdir(parents=True)
        (nixos / 'old-kernel.efi').write_bytes(b'old-kernel')
        (entries / 'nixos-old.conf').write_text('old entry')
        (nixos / 'stale-kernel.efi').write_bytes(b'stale')
        (entries / 'nixos-stale.conf').write_text('stale entry')
        (boot / 'loader/loader.conf').write_text('default nixos-old.conf\n')
        source = root / 'new-source'
        source.write_bytes(b'new-payload')

        ns['BOOT_MOUNT_POINT'] = boot
        ns['NIXOS_DIR'] = Path('EFI/nixos')
        roots = []
        if keep_old:
            roots.extend([
                BootFile(path=Path('EFI/nixos/old-kernel.efi'), writer=CopyWriter(source=source)),
                BootFile(path=Path('loader/entries/nixos-old.conf'), writer=CopyWriter(source=source)),
            ])
        roots.extend([
            BootFile(path=Path('EFI/nixos/new-kernel.efi'), writer=CopyWriter(source=source)),
            BootFile(path=Path('loader/entries/nixos-new.conf'), writer=CopyWriter(source=source)),
        ])

        garbage_collect(roots)
        before = sorted(str(p.relative_to(boot)) for p in boot.rglob('*') if p.is_file())

        original_copy = shutil.copyfileobj
        def fail_enospc(src, dst):
            dst.write(b'partial')
            dst.flush()
            raise OSError(errno.ENOSPC, 'synthetic no space left on device')
        shutil.copyfileobj = fail_enospc
        failure = None
        try:
            write_boot_files(roots, set())
        except OSError as e:
            failure = f'{type(e).__name__}:{e.errno}:{e.strerror}'
        finally:
            shutil.copyfileobj = original_copy
        after = sorted(str(p.relative_to(boot)) for p in boot.rglob('*') if p.is_file())
        print(f'case={name}')
        print(f'failure={failure}')
        print(f'before_write={before}')
        print(f'after_failure={after}')
        print(f'loader_conf={(boot / "loader/loader.conf").read_text().strip()}')
        print()

run_case('prior-generation-retained', keep_old=True)
run_case('prior-generation-not-selected', keep_old=False)

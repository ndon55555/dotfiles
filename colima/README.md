# Colima template

[`default.yaml`](default.yaml) is the template Colima uses when it creates a new
instance. `./install` links it to `~/.colima/_templates/default.yaml` on macOS.
It only affects instances created after it changes. Existing instances keep
their own `~/.colima/<profile>/colima.yaml`.

It has the same keys as Colima v0.10.3's
[built-in default](https://github.com/abiosoft/colima/blob/v0.10.3/embedded/defaults/colima.yaml).
The values below are the ones it changes.

## Changed from the defaults

| Key | Default | Here |
| --- | --- | --- |
| `vmType` | `qemu` | `vz` |
| `rosetta` | `false` | `true` |
| `mountType` | `sshfs` | `virtiofs` |
| `cpu` | `2` | `4` |
| `memory` | `2` (GiB) | `8` (GiB) |
| `disk` | `100` (GiB) | `120` (GiB) |

`vmType`, `mountType` and `arch` can't be changed after an instance is created.
To change them, delete the instance and create it again.

### `vmType: vz`

`vz` uses Apple's Virtualization.framework instead of QEMU. Both `rosetta` and
`mountType: virtiofs` need it. Lima's mount docs say: "the "virtiofs" mount type
is supported only on macOS 13 or above with `vmType: vz` config"
([Lima: Filesystem mounts](https://lima-vm.io/docs/config/mount/)).

### `rosetta: true`

amd64 (x86_64) containers run under Rosetta instead of QEMU user-mode emulation.
Lima's docs: "Rosetta is known to be much faster than QEMU User Mode Emulation"
([Lima: Intel-on-ARM and ARM-on-Intel](https://lima-vm.io/docs/config/multi-arch/)).
Rosetta must also be installed on the Mac itself. `./install` installs it if it's
missing.

Rosetta only handles 64-bit x86. 32-bit (i386) binaries still run under QEMU,
because `binfmt: true` registers `qemu-i386` in the VM.

To check that Rosetta is handling a container, look for Rosetta in its memory
mappings:

```sh
docker run --rm --platform linux/amd64 alpine grep -m1 rosetta /proc/self/maps
```

If it prints a line with `/mnt/lima-rosetta/rosetta`, Rosetta is in use. If it
prints nothing, the container is running under QEMU.

On macOS 28, Apple keeps only part of Rosetta for Mac apps. Rosetta for Linux
VMs is a separate Virtualization framework feature. An Apple engineer said it is
"not planned for deprecation"
([Apple Developer Forums](https://developer.apple.com/forums/thread/830176)).

### `mountType: virtiofs`

This changes how your home directory is shared into the VM, and so how fast and
how reliably bind mounts (`docker run -v ~/project:/app`) work.

**How each one works.** With sshfs, the VM reads your files over an SSH
connection: Lima's sshfs mode "exposes the host filesystem by running an SFTP
server on the host". virtiofs skips the network: it "is implemented via the
virtio-fs device", "using apple Virtualization.Framework shared directory on
macOS" ([Lima: Filesystem mounts](https://lima-vm.io/docs/config/mount/)).

**Speed.** The comments in [`default.yaml`](default.yaml#L185) call virtiofs
"the fastest of the options".

**Reliability.** The same comments call sshfs "the least reliable of the
options (when there are lots of concurrent reads or writes)", which is what
builds, test runs and file watchers do. sshfs also depends on the SSH
connection staying up. Lima: "A mount is disabled when the SSH connection was
shut down."

**Security.** Lima warns that with sshfs, "A compromised `sshfs` process in the
guest may have access to unexposed host directories." Lima doesn't give that
warning for virtiofs.

virtiofs only works with `vmType: vz` on macOS 13 or later (see above).

### `cpu: 4`, `memory: 8`, `disk: 120`

These are sizing choices, not fixes. On the 10-core, 16 GiB Mac this was set up
on, they give the VM 40% of the cores and half the memory, leaving the rest for
macOS. `disk` holds images, volumes and build cache, and
[`default.yaml`](default.yaml#L6) notes it "can only be increased after virtual
machine has been created", so it starts with some headroom. To override them
when creating one instance, use `colima start --cpus`, `--memory` and `--disk`.

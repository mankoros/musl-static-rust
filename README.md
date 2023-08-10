# MUSL static RUST

This repo contains two things:

- A docker image to build the [riscv-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain) with [libunwind](https://github.com/libunwind/libunwind), linking against [musl libc](https://musl.libc.org/).
- A rust project template to create fully static linked binaries for riscv64gc-unknown-linux-musl.

## Why?

Sometimes we need to create a fully static linked binary for riscv64gc-unknown-linux-musl. However, the default riscv-toolchain doesn't support it. Although there are many targets that can link against musl libc, `riscv64-unknown-linux-musl` doesn't exist yet. So, we have to deal with it by ourselves (and a GCC/G++ cross-compiling toolchain). Sad.

```bash
$ rustup target list | grep musl
aarch64-unknown-linux-musl
arm-unknown-linux-musleabi
arm-unknown-linux-musleabihf
armv5te-unknown-linux-musleabi
armv7-unknown-linux-musleabi
armv7-unknown-linux-musleabihf
i586-unknown-linux-musl
i686-unknown-linux-musl
mips-unknown-linux-musl
mips64-unknown-linux-muslabi64
mips64el-unknown-linux-muslabi64
mipsel-unknown-linux-musl
x86_64-unknown-linux-musl
```

## Requirements

### Install [Docker](https://www.docker.com/)

You can follow the instructions [here](https://docs.docker.com/install/).

### Install rustup and the required target

You can follow the instructions [here](https://www.rust-lang.org/tools/install).

Then, you need to add the nightly toolchains (should be automatically installed when you run the first `cargo build`) and riscv64gc-unknown-none-elf target:

```bash
rustup target add riscv64gc-unknown-none-elf 
```

> We need rust nightly in 2023-08-10 for the support of `build-std` argument in `.cargo/config.toml`.

> You can edit the `rust-toolchain.toml` file to choose your favorite nightly version.

## Usage

### Build and install the riscv-toolchain

By default, it's installed in `/opt/riscv`. You can change it by editing the `TOOLCHAIN_INSTALL` variable in the `Dockerfile`.

```bash
make build
make install
```

> You may need to use `sudo` for the `make install` command with the default `TOOLCHAIN_INSTALL` value.

> Notes: It requires a very good internet connection and a lot of time to build the toolchain.

> The building process required about 20 GiB of disk space, and the installed toolchain required about 1.5 GiB of disk space. So probably you should ask your firend to build them for you!

### Build the rust project

```bash
cargo build
```

Yes! It's that simple.

You can use `readelf -e target/riscv64gc-unknown-linux-musl/debug/$(PROJECT_NAME)` to check the binary. That's what I get:

```bash
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           RISC-V
    ...

Section Headers:
    ...

Program Headers:
  Type           Offset             VirtAddr           PhysAddr
                 FileSiz            MemSiz              Flags  Align
  LOPROC+0x3     0x000000000012cee2 0x0000000000000000 0x0000000000000000
                 0x0000000000000053 0x0000000000000000  R      0x1
  LOAD           0x0000000000000000 0x0000000000010000 0x0000000000010000
                 0x000000000011c99c 0x000000000011c99c  R E    0x1000
  LOAD           0x000000000011d800 0x000000000012d800 0x000000000012d800
                 0x000000000000f6d0 0x0000000000028ad8  RW     0x1000
  TLS            0x000000000011d800 0x000000000012d800 0x000000000012d800
                 0x0000000000000028 0x0000000000000052  R      0x8
  GNU_EH_FRAME   0x00000000000d961c 0x00000000000e961c 0x00000000000e961c
                 0x000000000000e1dc 0x000000000000e1dc  R      0x4
  GNU_STACK      0x0000000000000000 0x0000000000000000 0x0000000000000000
                 0x0000000000000000 0x0000000000000000  RW     0x10
  GNU_RELRO      0x000000000011d800 0x000000000012d800 0x000000000012d800
                 0x000000000000d800 0x000000000000d800  R      0x1

 Section to Segment mapping:
    ...
```

Ensure that `grep Machine` is `RISC-V` and `grep DYNAMIC` is empty!

However, with all the things statically linked, even a `hello-world` will need 20 MiB (without `strip` and `-Os`).

## Troubleshooting

### `cannot find crtbegin.o: No such file or directory`

Because we don't lock the commit of the riscv-toolchain (who can refuse a new compiler?), the version of GCC compiled may change and the path of the `crtbegin.o` may change too.

Basically what you need to check first is this line in `.cargo/config.toml`:

```
"-L/opt/riscv/lib/gcc/riscv64-unknown-linux-musl/12.2.0/",
```

You need to ensure the path is correct. Use `ls $(TOOLCHAIN_INSTALL)/lib/gcc/riscv64-unknown-linux-musl/` to check the version of the GCC.

## License

This repo itself is under MIT license. However, **if you statically link a library that is under GPL license, the binary will be under GPL license too**. So be careful when choosing libraries when you use this repo!
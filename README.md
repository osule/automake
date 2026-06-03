# automake

[GNU Automake](https://github.com/autotools-mirror/automake) plugin for the
[asdf](https://asdf-vm.com) version manager.

Versions are listed from the upstream git tags and built from the official GNU
release tarballs (`ftp.gnu.org`), which ship a pre-generated `./configure`.

## Dependencies

- `autoconf` (install the companion [autoconf plugin](https://github.com/osule/autoconf) or use your package manager)
- `perl`
- `make` and a C compiler

```shell
# Via asdf — install and activate autoconf first:
asdf plugin add autoconf https://github.com/osule/autoconf.git
asdf install autoconf latest && asdf global autoconf latest && asdf reshim

# macOS
brew install autoconf automake perl

# Debian / Ubuntu
sudo apt-get install autoconf perl make
```

## Usage

```shell
asdf plugin add automake https://github.com/osule/automake.git
asdf install automake latest
asdf global automake latest
automake --version
```

## Configuration

| Variable                     | Purpose                                       |
| ---------------------------- | --------------------------------------------- |
| `AUTOMAKE_CONFIGURE_OPTIONS` | Extra flags passed to `./configure`.          |
| `GNU_MIRROR`                 | Alternate GNU mirror (default `ftp.gnu.org`). |

## License

This plugin packages GNU Automake and adopts its license:
**GPL-2.0-or-later**. See [LICENSE](LICENSE).

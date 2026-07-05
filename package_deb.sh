#!/usr/bin/env bash
# Builds LibreSprite and packages it as a .deb for Debian/Ubuntu-based systems.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$REPO_ROOT/build-deb"
PKG_ROOT="$BUILD_DIR/pkgroot"

# Packages needed to configure/compile the project. libtinyxml2-dev and
# libarchive-dev are the two required at minimum; the rest are the other
# libraries LibreSprite links against on Linux.
BUILD_DEPS=(
  build-essential cmake git pkg-config dpkg-dev fakeroot
  zlib1g-dev libarchive-dev libtinyxml2-dev libpng-dev libfreetype6-dev
  libgif-dev libjpeg-dev libcurl4-openssl-dev libwebp-dev
  libx11-dev libxext-dev libxcursor-dev libxpm-dev libxxf86vm-dev
  libice-dev libxcb1-dev libsdl2-dev libsdl2-image-dev libpixman-1-dev
)

echo "==> Checking build dependencies"
missing=()
for pkg in "${BUILD_DEPS[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Installing missing build dependencies: ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
fi

echo "==> Fetching git submodules"
git -C "$REPO_ROOT" submodule update --init --recursive

echo "==> Configuring (Release)"
cmake -S "$REPO_ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
  -DWITH_DESKTOP_INTEGRATION=ON

echo "==> Building"
cmake --build "$BUILD_DIR" -j"$(nproc)"

echo "==> Installing into package root"
rm -rf "$PKG_ROOT"
DESTDIR="$PKG_ROOT" cmake --install "$BUILD_DIR"

VERSION="$(git -C "$REPO_ROOT" describe --tags --always 2>/dev/null | sed 's/^v//')"
[ -n "$VERSION" ] || VERSION="0.0.0"
ARCH="$(dpkg --print-architecture)"
INSTALLED_SIZE="$(du -sk "$PKG_ROOT" | cut -f1)"

echo "==> Detecting runtime library dependencies"
# dpkg-shlibdeps insists on a debian/control file relative to the cwd
# (unrelated to the DEBIAN/control we write below for dpkg-deb).
mkdir -p "$PKG_ROOT/debian" && touch "$PKG_ROOT/debian/control"
SHLIBS_DEPENDS="$(cd "$PKG_ROOT" && dpkg-shlibdeps -O "./usr/bin/libresprite" 2>/dev/null | sed -n 's/^shlibs:Depends=//p')"
rm -rf "$PKG_ROOT/debian"

MAINTAINER_NAME="$(git -C "$REPO_ROOT" config user.name || true)"
MAINTAINER_EMAIL="$(git -C "$REPO_ROOT" config user.email || true)"
[ -n "$MAINTAINER_NAME" ] || MAINTAINER_NAME="Unknown"
[ -n "$MAINTAINER_EMAIL" ] || MAINTAINER_EMAIL="unknown@localhost"

mkdir -p "$PKG_ROOT/DEBIAN"
cat > "$PKG_ROOT/DEBIAN/control" <<EOF
Package: libresprite
Version: ${VERSION}
Section: graphics
Priority: optional
Architecture: ${ARCH}
Installed-Size: ${INSTALLED_SIZE}
Depends: ${SHLIBS_DEPENDS}
Maintainer: ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>
Description: Create and animate your sprites
 LibreSprite is a free and open source program for creating and animating
 pixel art, forked from the last GPLv2 release of Aseprite.
EOF

DEB_FILE="$REPO_ROOT/libresprite_${VERSION}_${ARCH}.deb"
fakeroot dpkg-deb --build "$PKG_ROOT" "$DEB_FILE"
echo "==> Package created: $DEB_FILE"

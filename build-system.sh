echo "homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /Users/haass/.zprofile\n    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> /Users/haass/.zprofile\n    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo 'alias dir="ls -la --color"' >> .zshrc

echo "build system"
brew install python3
ln -s /opt/homebrew/bin/python3 /opt/homebrew/bin/python
mkdir test
git clone git@github.com:vvvrrooomm/ardour-build.git
cd ardour-build
rm waf
curl https://waf.io/waf-2.1.9 -o waf
chmod u+x waf
brew install boost
export PKG_CONFIG_PATH=/opt/homebrew/lib/pkgconfig
# runs on brew install boost
# export CPLUS_INCLUDE_PATH=/opt/homebrew/Cellar/boost/1.85.0_3/include
# export LDFLAGS="-L/opt/homebrew/opt/boost@1.85/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/boost@1.85/include"
brew install pkg-config glib glibmm@2.66 libsndfile libarchive liblo taglib vamp-plugin-sdk rubberband libusb jack fftw aubio libpng pango libsigc++@2 cairomm@1.14 pangomm@2.46 lv2 cppunit libwebsockets lrdf serd sordw sratom lilv
export PKG_CONFIG_PATH="/opt/homebrew/opt/libarchive/lib/pkgconfig:$PKG_CONFIG_PATH"

brew info libarchive
export LDFLAGS="-L/opt/homebrew/opt/libarchive/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libarchive/include"
echo 'export PATH="/opt/homebrew/opt/libarchive/bin:$PATH"' >> ~/.zshrc


git clone https://github.com/Ardour/ardour
cd ardour
export LDFLAGS="$LDFLAGS -L/opt/homebrew/opt/libarchive/lib"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/opt/libarchive/include"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/raptor/2.0.16_1/include/raptor2"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/glibmm@2.66/2.66.8/include"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/fftw/3.3.10_3/include"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/openssl@3/3.6.1/include/"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/jack/1.9.22_1/include/"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/cairo/1.18.4/include/"
export CPPFLAGS="$CPPFLAGS -I/opt/homebrew/Cellar/libsndfile/1.2.2_1/include"
git apply ../ardour-build/001-macos-disable-visibility.patch
./Waf configure --boost-include=/opt/homebrew//Cellar/boost/1.90.0_1/include --arm64 --prefix=/opt/homebrew/Cellar/ardour/9.2.git
./Waf build
./waf install --destdir=dist/
cd dist
find . -perm +111 -type f -exec install_name_tool "{}" -add_rpath /opt/homebrew/Cellar/ardour/9.2.git \;
find . -name "*.dylib" -exec install_name_tool -id /opt/homebrew/Cellar/ardour/9.2.git/$(basename {}) {} \;
tar -czf ardour-9.2.git.tar.gz dist/opt/homebrew/Cellar/ardour/9.2.git
hash=$(shasum -a 256 ardour-9.2.git.tar.gz)

class Ardour < Formula
  desc "Digital Audio Workstation"
  homepage "https://ardour.org"
  head "https://github.com/Ardour/ardour.git"

  depends_on "python@3.11"
  depends_on "boost"
  depends_on "pkg-config"
  depends_on "glib"
  depends_on "glibmm@2.66"
  depends_on "libsndfile"
  depends_on "libarchive"
  depends_on "liblo"
  depends_on "taglib"
  depends_on "vamp-plugin-sdk"
  depends_on "rubberband"
  depends_on "libusb"
  depends_on "jack"
  depends_on "fftw"
  depends_on "aubio"
  depends_on "libpng"
  depends_on "pango"
  depends_on "libsigc++@2"
  depends_on "cairomm@1.14"
  depends_on "pangomm@2.46"
  depends_on "lv2"
  depends_on "cppunit"
  depends_on "libwebsockets"
  depends_on "lrdf"
  depends_on "serd"
  depends_on "sord"
  depends_on "sratom"
  depends_on "lilv"
  depends_on "raptor"
  depends_on "openssl@3"


  def install
    ENV["PKG_CONFIG_PATH"] = "#{Formula["libarchive"].opt_lib}/pkgconfig:#{ENV["PKG_CONFIG_PATH"]}"
    ENV.append "LDFLAGS", "-L#{Formula["libarchive"].opt_lib}"
    ENV.append "CPPFLAGS", "-I#{Formula["libarchive"].opt_include}"
    ENV.append "CPPFLAGS", "-I#{Formula["raptor"].opt_include}"
    ENV.append "CPPFLAGS", "-I#{Formula["raptor"].opt_include}/raptor2"
    ENV.append "LDFLAGS", "-L#{Formula["raptor"].opt_lib}"

    # Ensure a usable waf script exists
    waf = buildpath/"waf"
    unless waf.exist?
      system "curl", "-L", "https://waf.io/waf-2.1.9", "-o", "waf"
      chmod 0755, "waf"
    end

    # Apply macOS visibility define to disable symbol visibility problems
    if OS.mac?
      inreplace "libs/tk/ydk/wscript",
        "obj.includes += ['quartz', 'quartz/ydk', 'ydk/quartz']",
        "obj.includes += ['quartz', 'quartz/ydk', 'ydk/quartz']\n        obj.defines += ['DISABLE_VISIBILITY']"

      inreplace "libs/tk/ytk/wscript",
        "obj.uselib   += ' OSX' #  -framework Cocoa -framework CoreFoundation -framework ApplicationServices",
        "obj.uselib   += ' OSX' #  -framework Cocoa -framework CoreFoundation -framework ApplicationServices\n        obj.defines += ['DISABLE_VISIBILITY']"
    end

    system "./waf", "configure", "--boost-include=#{Formula["boost"].opt_include}", "--arm64", "--prefix=#{prefix}"
    system "./waf", "build"
    system "./waf", "install", "--destdir=#{buildpath}/dist"

    # Move installed tree into prefix
    prefix.install Dir["dist/*"]

    # Add runtime rpath to any executables and fix dylib ids
    if OS.mac?
      mach_o_magics = ["\xFE\xED\xFA\xCE", "\xCE\xFA\xED\xFE", "\xFE\xED\xFA\xCF", "\xCF\xFA\xED\xFE"]
      Dir["#{prefix}/**/*"].each do |f|
        next if File.directory?(f)
        begin
          header = File.open(f, "rb") { |io| io.read(4) } || ""
        rescue
          header = ""
        end
        is_macho = mach_o_magics.include?(header)

        if is_macho && File.executable?(f)
          system "install_name_tool", f, "-add_rpath", opt_prefix
        end

        if f.end_with?(".dylib")
          system "install_name_tool", "-id", "#{opt_prefix}/#{Pathname.new(f).relative_path_from(prefix)}", f
        end
      end
    end
  end

  test do
    # basic smoke test: ensure executable runs and prints version
    output = shell_output("#{bin}/ardour9 --version")
    assert_match "Ardour", output
  end
end

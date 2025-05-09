class Bsc < Formula
  desc "Bluespec Compiler (BSC)"
  homepage "https://github.com/B-Lang-org/bsc"
  url "https://github.com/B-Lang-org/bsc.git", tag: "2025.01.1"
  license "BSD-3-Clause"
  head "https://github.com/B-Lang-org/bsc.git", branch: "main"

  depends_on "autoconf" => :build
  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gperf" => :build
  depends_on "make" => :build
  depends_on "pkg-config" => :build
  depends_on "gmp"
  depends_on "icarus-verilog"
  depends_on "tcl-tk@8"

  def install
    system "cabal", "update"
    system "cabal", "v1-install",
           "old-time",
           "regex-compat",
           "split",
           "syb"

    with_env(
      PREFIX:      libexec,
      GHCJOBS:     "#{Hardware::CPU.cores}",
      GHCRTSFLAGS: "+RTS -M4500M -A128m -RTS",
    ) do
      system "make", "install-src", "-j", Hardware::CPU.cores
    end

    bin.write_exec_script libexec/"bin/bsc"
    bin.write_exec_script libexec/"bin/bluetcl"
    lib.install_symlink Dir[libexec/"lib/SAT"/shared_library("*")]
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test bsc`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system bin/"program", "do", "something"`.
    system "false"
  end
end

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
    (testpath/"FibOne.bsv").write <<~BSV
      (* synthesize *)
      module mkFibOne();
        // register containing the current Fibonacci value
        Reg#(int) this_fib();              // interface instantiation
        mkReg#(0) this_fib_inst(this_fib); // module instantiation
        // register containing the next Fibonacci value
        Reg#(int) next_fib();
        mkReg#(1) next_fib_inst(next_fib);

        rule fib;  // predicate condition always true, so omitted
            this_fib <= next_fib;
            next_fib <= this_fib + next_fib;  // note that this uses stale this_fib
            $display("%0d", this_fib);
            if ( this_fib > 50 ) $finish(0) ;
        endrule: fib
      endmodule: mkFibOne
    BSV

    expected_output = <<~EOS
      0
      1
      1
      2
      3
      5
      8
      13
      21
      34
      55
    EOS

    # Checking Verilog generation
    system "#{bin}/bsc", "-verilog",
                         "FibOne.bsv"

    # Checking Verilog simulation
    system "#{bin}/bsc", "-vsim", "verilator",
                         "-e", "mkFibOne",
                         "-o", "mkFibOne.vexe",
                         "mkFibOne.v"
    assert_match expected_output, shell_output("./mkFibOne.vexe")
    

    # Checking Bluesim object generation
    system "#{bin}/bsc", "-sim",
                         "FibOne.bsv"

    # Checking Bluesim simulation
    system "#{bin}/bsc", "-sim",
                         "-e", "mkFibOne",
                         "-o", "mkFibOne.bexe",
                         "mkFibOne.ba"
    assert_equal expected_output, shell_output("./mkFibOne.bexe")
  end
end

class Emscripten < Formula
  desc "LLVM bytecode to JavaScript compiler"
  homepage "https://emscripten.org/"

  stable do
    url "https://github.com/emscripten-core/emscripten/archive/1.39.9.tar.gz"
    sha256 "35549060dbbacb73f307e1e6ac016afc0f14e1ff4e936a426701fa0e836a83dc"

    resource "fastcomp" do
      url "https://github.com/emscripten-core/emscripten-fastcomp/archive/1.39.9.tar.gz"
      sha256 "d4eb8738e45d86b53457b7dbd77d4fa4775bf63e9573e819ff44e1ece0b1029f"
    end

    resource "fastcomp-clang" do
      url "https://github.com/emscripten-core/emscripten-fastcomp-clang/archive/1.39.9.tar.gz"
      sha256 "fed133e722bcc114420ee51e90ee3d077a577e135ba8df8e1d50faa072afb7c3"
    end
  end

  bottle do
    cellar :any
    sha256 "5ebddfe23efb4d01152414423d8211d116c21b3942463715ba6ced791f2aba0e" => :catalina
    sha256 "d1ac440312334da08cea61514688993b248c216e8b4c96051aeeec30f62505d2" => :mojave
    sha256 "ef3290a6999fce9a6b429d67c33c2461bb89d625bc94b57444acfd6075a9de6f" => :high_sierra
  end

  head do
    url "https://github.com/emscripten-core/emscripten.git", :branch => "incoming"

    resource "fastcomp" do
      url "https://github.com/emscripten-core/emscripten-fastcomp.git", :branch => "incoming"
    end

    resource "fastcomp-clang" do
      url "https://github.com/emscripten-core/emscripten-fastcomp-clang.git", :branch => "incoming"
    end
  end

  depends_on "cmake" => :build
  depends_on "binaryen"
  depends_on "node"
  depends_on "python"
  depends_on "yuicompressor"

  def install
    ENV.cxx11

    # All files from the repository are required as emscripten is a collection
    # of scripts which need to be installed in the same layout as in the Git
    # repository.
    libexec.install Dir["*"]

    (buildpath/"fastcomp").install resource("fastcomp")
    (buildpath/"fastcomp/tools/clang").install resource("fastcomp-clang")

    cmake_args = std_cmake_args.reject { |s| s["CMAKE_INSTALL_PREFIX"] }
    cmake_args = [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DCMAKE_INSTALL_PREFIX=#{libexec}/llvm",
      "-DLLVM_TARGETS_TO_BUILD='X86;JSBackend'",
      "-DLLVM_INCLUDE_EXAMPLES=OFF",
      "-DLLVM_INCLUDE_TESTS=OFF",
      "-DCLANG_INCLUDE_TESTS=OFF",
      "-DOCAMLFIND=/usr/bin/false",
      "-DGO_EXECUTABLE=/usr/bin/false",
    ]

    mkdir "fastcomp/build" do
      system "cmake", "..", *cmake_args
      system "make"
      system "make", "install"
    end

    %w[em++ em-config emar emcc emcmake emconfigure emlink.py emmake
       emranlib emrun emscons].each do |emscript|
      bin.install_symlink libexec/emscript
    end
  end

  def caveats; <<~EOS
    Manually set LLVM_ROOT to
      #{opt_libexec}/llvm/bin
    and BINARYEN_ROOT to
      #{Formula["binaryen"].opt_prefix}
    in ~/.emscripten after running `emcc` for the first time.
  EOS
  end

  test do
    system bin/"emcc"
    assert_predicate testpath/".emscripten", :exist?, "Failed to create sample config"
  end
end

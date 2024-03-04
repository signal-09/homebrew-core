class Jackett < Formula
  desc "API Support for your favorite torrent trackers"
  homepage "https://github.com/Jackett/Jackett"
  url "https://github.com/Jackett/Jackett/archive/refs/tags/v0.21.1939.tar.gz"
  sha256 "bbd07c27d9169a418ba2c18030193cb95ed0d340febd55f6d60afd1a6814e15c"
  license "GPL-2.0-only"
  head "https://github.com/Jackett/Jackett.git", branch: "master"

  bottle do
    sha256 cellar: :any,                 arm64_ventura:  "706ef6577fe862ac100fa7ab813469e01401cc786d790a424fd529f540ad15b7"
    sha256 cellar: :any,                 arm64_monterey: "a9da39c875c8bacd76d9a2a48109c80bb10048bde3437936d150b5a8432a636e"
    sha256 cellar: :any,                 ventura:        "fbcfc9259cc5825d307b9394fe77c60908c3d8003df092b95018ac8684e7477c"
    sha256 cellar: :any,                 monterey:       "27dad82b4c9613a972f09398089b6f45a5f2d21f17818df3101c2abb82aee434"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4116daded16c1b7f5a124de50dd4c92f07e11ff6b0bc83058456503139fd3dc2"
  end

  depends_on "dotnet@6"

  def install
    dotnet = Formula["dotnet@6"]
    os = OS.mac? ? "osx" : OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s

    args = %W[
      --configuration Release
      --framework net#{dotnet.version.major_minor}
      --output #{libexec}
      --runtime #{os}-#{arch}
      --no-self-contained
    ]
    if build.stable?
      args += %W[
        /p:AssemblyVersion=#{version}
        /p:FileVersion=#{version}
        /p:InformationalVersion=#{version}
        /p:Version=#{version}
      ]
    end

    system "dotnet", "publish", "src/Jackett.Server", *args

    (bin/"jackett").write_env_script libexec/"jackett", "--NoUpdates",
      DOTNET_ROOT: "${DOTNET_ROOT:-#{dotnet.opt_libexec}}"
  end

  service do
    run opt_bin/"jackett"
    keep_alive true
    working_dir opt_libexec
    log_path var/"log/jackett.log"
    error_log_path var/"log/jackett.log"
  end

  test do
    assert_match(/^Jackett v#{Regexp.escape(version)}$/, shell_output("#{bin}/jackett --version 2>&1; true"))

    port = free_port

    pid = fork do
      exec "#{bin}/jackett", "-d", testpath, "-p", port.to_s
    end

    begin
      sleep 10
      assert_match "<title>Jackett</title>", shell_output("curl -b cookiefile -c cookiefile -L --silent http://localhost:#{port}")
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end

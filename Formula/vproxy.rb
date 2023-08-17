# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class Vproxy < Formula
  desc "Zero-config virtual proxies with tls"
  homepage "https://github.com/jittering/vproxy"
  version "0.12.2"

  depends_on "mkcert"
  depends_on "nss"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jittering/vproxy/releases/download/v0.12.2/vproxy_darwin_arm64.tar.gz"
      sha256 "acdf00e3741c19fc63abca3d6858399b15199bef32f9f2ea44851f62076ec797"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/jittering/vproxy/releases/download/v0.12.2/vproxy_darwin_amd64.tar.gz"
      sha256 "db36ae0b2e2693253bffa6301474c743a7982d57f7b96f604a521efdc0804a92"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/jittering/vproxy/releases/download/v0.12.2/vproxy_linux_arm64.tar.gz"
      sha256 "a3d71a582f0b3295880c03150582b50325f665b88d77ad635270d244912010da"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/jittering/vproxy/releases/download/v0.12.2/vproxy_linux_amd64.tar.gz"
      sha256 "dd531e37ce3368f416b85559af557e3481fd046b7fb700365f4623dc668887f6"

      def install
        bin.install "vproxy"

        bash_output = Utils.safe_popen_read("#{bin}/vproxy", "bash_completion")
        (bash_completion/"vproxy").write bash_output
      end
    end
  end

  def post_install
    str = <<~EOF
          # Sample config file
          # All commented settings below are defaults

          # Enable verbose output
          #verbose = false

          [server]
          # Enable verbose output (for daemon only)
          #verbose = false

          # IP on which server will listen
          # To listen on all IPs, set listen = "0.0.0.0"
          #listen = "127.0.0.1"

          # Ports to listen on
          #http = 80
          #https = 443


          # CAROOT path
          caroot_path = "#{var}/vproxy/caroot"

          # Path where generated certificates should be stored
          cert_path = "#{var}/vproxy/cert"

          [client]
          # Enable verbose output (for client only)
          #verbose = false

          #host = "127.0.0.1"
          #http = 80

          # Use this in local config files, i.e., a .vproxy.conf file located in a
          # project folder
          #bind = ""
        EOF
        str = str.gsub(/^[\t ]+/, "") # trim leading spaces
        conf_file = "#{etc}/vproxy.conf"

        # always write new sample file
        File.open("#{conf_file}.sample", "w") do |f|
          f.puts str
        end

        # only create default conf if it doesn't already exist
        unless File.exist?(conf_file)
          File.open(conf_file, "w") do |f|
            f.puts str
          end
        end

        # setup var dir, if needed
        unless File.exist?("#{var}/vproxy")
          puts ohai_title("creating #{var}/vproxy")

          # Create/migrate caroot
          mkdir_p("#{var}/vproxy/caroot", mode: 0755)
          mkcert_caroot = `#{bin}/vproxy caroot --default`.strip
          pems = Dir.glob("#{mkcert_caroot}/*.pem")
          if pems.empty?
            puts ohai_title("caroot not found; create with: vaproxy caroot --create")
          else
            puts ohai_title("migrating caroot")
            cp(pems, "#{var}/vproxy/caroot")
          end

          # Create/migrate cert path
          puts ohai_title("created cert dir #{var}/vproxy/cert")
          mkdir_p("#{var}/vproxy/cert", mode: 0755)
          if File.exist?(old_cert_path)
            certs = Dir.glob("#{old_cert_path}/*.pem")
            puts ohai_title("migrating #{certs.size} certs")
            errs = 0
            certs.each do |cert|
              if File.readable?(cert)
                cp(cert, "#{var}/vproxy/cert")
              else
                errs += 1
              end
            end
            onoe("couldn't read #{errs} cert(s)") if errs.positive?
          end
        end
  end

  def caveats
    <<~EOS
      To install your local root CA:
        $ vproxy caroot --create

      vproxy data is stored in #{var}/vproxy

      The local root CA is in #{var}/vproxy/caroot;
        certs will be stored in #{var}/vproxy/cert when generated.

      See vproxy documentation for more info
    EOS
  end

  service do
    name "vproxy"
    run ["#{bin}/vproxy", "daemon"]
    keep_alive successful_exit: false
    working_directory "#{var}"
    log_path "#{var}/log/vproxy.log"
    error_log_path "#{var}/log/vproxy.log"
  end

  test do
    system "#{bin}/vproxy", "--version"
  end
end

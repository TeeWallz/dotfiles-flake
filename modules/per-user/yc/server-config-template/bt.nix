{ config, ... }: {
  fileSystems."/home/bt" = {
    device = "rpool/data/bt";
    fsType = "zfs";
    options = [ "noatime" "X-mount.mkdir=755" ];
  };

  fileSystems."/var/lib/transmission/.config" = {
    device = "/home/bt/.config";
    fsType = "none";
    options = [ "bind" "X-mount.mkdir=755" ];
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    extraConfig = ''
      guest account = nobody
      map to guest = bad user
      server smb encrypt = off
    '';
    shares = {
      bt = {
        path = "/home/bt";
        "read only" = true;
        browseable = "yes";
        "guest ok" = "yes";
      };
    };
  };

  services.transmission = {
    enable = true;
    openFirewall = true;
    home = "/var/lib/transmission";
    performanceNetParameters = true;
    settings = {
      dht-enabled = true;
      download-dir = "/home/bt/已下载";
      download-queue-enabled = false;
      idle-seeding-limit-enabled = false;
      incomplete-dir = "/home/bt/未完成";
      incomplete-dir-enabled = true;
      lpd-enabled = true;
      message-level = 1;
      pex-enabled = true;
      port-forwarding-enabled = false;
      preallocation = 1;
      prefetch-enabled = true;
      queue-stalled-enabled = true;
      rename-partial-files = true;
      rpc-authentication-required = false;
      rpc-bind-address = "0.0.0.0";
      rpc-enabled = true;
      rpc-host-whitelist = "";
      rpc-host-whitelist-enabled = true;
      rpc-port = 9091;
      rpc-url = "/transmission/";
      rpc-username = "";
      rpc-whitelist = "127.0.0.1,::1";
      rpc-whitelist-enabled = true;
      scrape-paused-torrents-enabled = true;
      script-torrent-done-enabled = false;
      seed-queue-enabled = false;
      utp-enabled = true;
    };
  };
}

{ config, lib, pkgs, ... }:

with lib;

let
  # Convert nix expressions to burp config
  #
  boolToOneZero = b: if b then "1" else "0";

  burpToString = x: if builtins.typeOf x == "bool"
                    then boolToOneZero x
                    else toString x;

  burpConfig = source:
	  concatStrings (map
			  (key: "${key} = ${burpToString (getAttr key source)}\n")
			  (attrNames source));

  burpRepeatStatement = key: array:
	  concatStrings (map
			  (statement: "${key} = ${burpToString statement}\n")
			  array);

  server_cfg = config.services.burp-server;
  server_conf = pkgs.writeText "burp-server.conf"
    ''
      mode = server
      user = ${server_cfg.user}
      group = ${server_cfg.group}
      listen = ${server_cfg.listen}
      listen_status = ${server_cfg.listen_status}

      clientconfdir = /etc/burp/clientconfdir

      syslog = 1
      stdout = 0

      pidfile = ${server_cfg.pidfile}
      directory = ${server_cfg.spoolDir}
      compression = ${server_cfg.compression}

      ca_burp_ca = ${pkgs.burp}/bin/burp_ca
      ca_name = ${server_cfg.caName}
      ca_server_name = ${server_cfg.caServerName}
      ca_conf = ${server_cfg.caConf}
      ssl_cert_ca = ${server_cfg.sslCertCa}
      ssl_cert = ${server_cfg.sslCert}
      ssl_key = ${server_cfg.sslKey}
      ssl_dhfile = ${server_cfg.sslDhfile}

      ${burpRepeatStatement "keep" server_cfg.keep}
      ${burpRepeatStatement "timer_arg" server_cfg.timerArg}

      ${burpConfig server_cfg.config}
    '';
  ca_conf = pkgs.writeText "CA.cnf"
    ''
      # simple config for burp_ca
      CA_DIR                  = ${server_cfg.caDir}/CA
      
      [ ca ]
      dir                     = $ENV::CA_DIR
      database                = $dir/index.txt
      serial                  = $dir/serial.txt
      certs                   = $dir/certs
      new_certs_dir           = $dir/newcerts
      crlnumber               = $dir/crlnumber.txt
      
      unique_subject          = no
      
      default_md              = sha256
      default_days            = 7300
      default_crl_days        = 7300
      
      #????
      name_opt                = ca_default
      cert_opt                = ca_default
      
      x509_extensions         = usr_cert
      copy_extensions         = copy
      policy                  = policy_anything
      
      [ usr_cert ]
      basicConstraints        = CA:FALSE
      
      [ policy_anything ]
      commonName              = supplied
    '';
  client_config_files = (map
    (client_name: { name = "burp/clientconfdir/${client_name}";
                    value = { text = "${burpConfig (getAttr client_name server_cfg.clients)}"; }; })
    (attrNames server_cfg.clients));
in {
  meta.maintainers = with maintainers; [ otwieracz ];

  options = {
    services.burp-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Burp Server";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "" ;
      };

      group = mkOption {
        type = types.str;
        default = "root";
        description = "" ;
      };

      pidfile = mkOption {
        type = types.str;
        default = "/var/run/burp-server.pid";
        description = "" ;
      };

      spoolDir = mkOption {
        type = types.str;
        default = "/var/lib/burp-server/spool";
        description = "" ;
      };

      compression = mkOption {
        type = types.str;
        default = "zlib9";
        description = "" ;
      };

      listen = mkOption {
        type = types.str;
        default = "0.0.0.0:4971";
        description = "" ;
      };

      listen_status = mkOption {
        type = types.str;
        default = "0.0.0.0:4972";
        description = "" ;
      };

      caDir = mkOption {
        type = types.str;
        default = "/var/lib/burp-server/ca";
        description = "" ;
      };

      caName = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "" ;
      };

      caServerName = mkOption {
        type = types.str;
        default = "${config.networking.hostName}-server";
        description = "" ;
      };

      keep = mkOption {
        type = with types; listOf int;
        default = [7 31 12];
        description = "" ;
      };

      timerArg = mkOption {
        type = with types; listOf string;
        default = ["20h" "Mon,Tue,Wed,Thu,Fri,00,01,02,03,04,05,19,20,21,22,23" "Sat,Sun,00,01,02,03,04,05,06,07,08,17,18,19,20,21,22,23"];
        description = "" ;
      };

      caConf = mkOption {
        type = types.str;
        default = "/etc/burp/CA.cnf";
        description = "";
      };

      sslCertCa = mkOption {
        type = types.str;
        default = "${config.services.burp-server.caDir}/ssl_cert_ca.pem";
        description = "";
      };

      sslCert = mkOption {
        type = types.str;
        default = "${config.services.burp-server.caDir}/ssl_cert-server.pem";
        description = "";
      };

      sslKey = mkOption {
        type = types.str;
        default = "${config.services.burp-server.caDir}/ssl_cert-server.key";
        description = "";
      };

      sslDhfile = mkOption {
        type = types.str;
        default = "${config.services.burp-server.caDir}/dhfile.pem";
        description = "";
      };

      config = mkOption {
        default = {
          max_children = 5;
          dedup_group = "global";
          hardlinked_archive = true;
          working_dir_recovery_method = "delete";
          umask = "0022";
          client_can_delete = true;
          client_can_diff = true;
          client_can_force_backup = true; 
          client_can_list = true; 
          client_can_monitor = true; 
          client_can_restore = true;
          client_can_verify = true; 
          version_warn = true;
          ca_crl_check = true;
        };
        description = ''
          Other Burp Server configuration directives. Defaults come from default burp configuration file
        '';
        type = with types; attrsOf types.unspecified;
      };

      clients = mkOption {
        default = {};
        example = {
          "some-client.foo" = {
            password = "my-password";
          };
        };
        description = ''
          Burp Servers clients specifications. 
        '';
        type = with types; attrsOf types.unspecified;
      };
    };
  };


  config = mkIf (server_cfg.enable ) { #|| client_cfg.enable) {
    environment.etc = {
     "burp/server.conf" = {
       enable = server_cfg.enable;
       source = server_conf;
     };
     "burp/CA.cnf" = {
       enable = server_cfg.enable;
       source = ca_conf;
     };
    } // listToAttrs client_config_files;


    systemd.services.burp-server = mkIf server_cfg.enable {
      after = [ "network.target" ];
      description = "Burp Server";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.burp pkgs.openssl pkgs.nettools ];
      restartTriggers = [ config.environment.etc."burp/server.conf".source ];
      reloadIfChanged = true;
      serviceConfig = {
        ExecStart = "${pkgs.burp}/bin/burp -F -c /etc/burp/server.conf";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        LogsDirectory = "burp";
        StateDirectory = "burp";
      };
      preStart = ''
        mkdir -p "${server_cfg.spoolDir}"
        chown ${server_cfg.user}:${server_cfg.group} "${server_cfg.spoolDir}"
        mkdir -p "${server_cfg.caDir}"
        chown -R ${server_cfg.user}:${server_cfg.group} "${server_cfg.caDir}"
      '';
    };

    environment.systemPackages = [ pkgs.burp ];
  };
}

{ config, lib, pkgs, ... }:

# TODO: test configuration when building nixexpr (use -t parameter)
# TODO: support sqlite3 (it's deprecate?) and mysql

with lib;

let
  libDir = "/var/lib/bacula";

  # Convert nix expressions to bacula config
  #
  boolToYesNo = b: if b then "yes" else "no";

  baculaToString = x: if builtins.typeOf x == "bool"
                      then boolToString x
                      else toString x;

  ## Recursively handle nested Bacula sets and lists
  ##
  baculaSet = parentKey: input:
  if builtins.typeOf input == "set"
  # Handle set of key = value
  then "{\n" + toString (map (key: "${key} ${baculaSet key (getAttr key input)}\n")
                             (attrNames input)
               ) + "\n}"
  # Handle where value is [list, of, values], then repeat it with parentKey
  else if builtins.typeOf input == "list"
       then " = " + (head input) + "\n" + toString (map (value: "${parentKey} = ${value}\n")
                                           (tail input)) + "\n"
       else "= ${baculaToString input}";

  # Generate one top-level bacula section
  baculaSection = type: source: section_defaults: name:
    let section = section_defaults // (getAttr name source); in
    "${type} {\n Name = ${name}\n " + (baculaToString (
       map
         (key: "${key} ${baculaSet key (getAttr key section)}\n")
         (attrNames section)
    )) + "\n}";

  # There are some defaults which can be overriden, but by default it guarantees proper
  # directory permissions for daemons, etc
  #
  sd_cfg_storage_default = {
    WorkingDirectory = "${sd_cfg.workdir}";
    "Pid Directory" = "/run";
  };

  fd_cfg_client_default = {
    WorkingDirectory = "${fd_cfg.workdir}";
    "Pid Directory" = "/run";
  };

  dir_cfg_director_default = {
    WorkingDirectory = "${dir_cfg.workdir}";
    QueryFile = "${pkgs.bacula}/etc/query.sql";
    "Pid Directory" = "/run";
  };

  dir_cfg_client_default = {
    Catalog = "PostgreSQL";
  };

  dir_cfg_job_default = {
    Messages = "Standard";
  };

  dir_cfg_jobDefs_default = {
    Type = "Backup";
    Messages = "Standard";
  };

  fd_cfg = config.services.bacula-fd;
  fd_conf = pkgs.writeText "bacula-fd.conf"
    ''
      ${baculaToString (map (baculaSection "Client" fd_cfg.client fd_cfg_client_default) (attrNames fd_cfg.client))}
      ${baculaToString (map (baculaSection "Director" fd_cfg.director {}) (attrNames fd_cfg.director))}
      ${baculaToString (map (baculaSection "Messages" fd_cfg.messages {}) (attrNames fd_cfg.messages))}
    '';

  sd_cfg = config.services.bacula-sd;
  sd_conf = pkgs.writeText "bacula-sd.conf" 
    ''
      ${baculaToString (map (baculaSection "Storage" sd_cfg.storage sd_cfg_storage_default) (attrNames sd_cfg.storage))}
      ${baculaToString (map (baculaSection "Device" sd_cfg.device {}) (attrNames sd_cfg.device))}
      ${baculaToString (map (baculaSection "Director" sd_cfg.director {}) (attrNames sd_cfg.director))}
      ${baculaToString (map (baculaSection "Messages" sd_cfg.messages {}) (attrNames sd_cfg.messages))}
    '';

  dir_cfg = config.services.bacula-dir;
  dir_conf = pkgs.writeText "bacula-dir.conf" 
    ''
      ${baculaToString (map (baculaSection "Director" dir_cfg.director dir_cfg_director_default) (attrNames dir_cfg.director))}
      ${baculaToString (map (baculaSection "Job" dir_cfg.job dir_cfg_job_default) (attrNames dir_cfg.job))}
      ${baculaToString (map (baculaSection "JobDefs" dir_cfg.jobDefs dir_cfg_jobDefs_default) (attrNames dir_cfg.jobDefs))}
      ${baculaToString (map (baculaSection "Schedule" dir_cfg.schedule {}) (attrNames dir_cfg.schedule))}
      ${baculaToString (map (baculaSection "FileSet" dir_cfg.fileSet {}) (attrNames dir_cfg.fileSet))}
      ${baculaToString (map (baculaSection "Client" dir_cfg.client dir_cfg_client_default) (attrNames dir_cfg.client))}
      ${baculaToString (map (baculaSection "Storage" dir_cfg.storage {}) (attrNames dir_cfg.storage))}
      ${baculaToString (map (baculaSection "Pool" dir_cfg.pool {}) (attrNames dir_cfg.pool))}
      ${baculaToString (map (baculaSection "Catalog" dir_cfg.catalog {}) (attrNames dir_cfg.catalog))}
      ${baculaToString (map (baculaSection "Messages" dir_cfg.messages {}) (attrNames dir_cfg.messages))}
      ${baculaToString (map (baculaSection "Console" dir_cfg.console {}) (attrNames dir_cfg.console))}
      ${baculaToString (map (baculaSection "Counter" dir_cfg.counter {}) (attrNames dir_cfg.counter))}
    '';
in {
  options = {
    services.bacula-fd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Bacula File Daemon.
        '';
      };

      workdir = mkOption {
        type = types.string;
        default = "/var/lib/bacula-fd/";
        description = ''
          Bacula File Daemon workdir. It's used in every `FileDaemon` definition only if `WorkingDirectory` is not specifically provided.
This way in default way it handles all the permissions and directory creation.
        '';
      };

      director = mkOption {
        default = {};
        description = ''
          This option defines Director resources in Bacula File Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };

      client = mkOption {
        default = {};
        description = ''
          This option defines Client resources in Bacula File Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      messages = mkOption {
        default = { 
                    Standard = {
		      syslog = "all, !skipped, !restored";
                    };
                  };
        description = ''
          This option defines Messages resources in Bacula File Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
    };

    services.bacula-sd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable Bacula Storage Daemon.
        '';
      };

      workdir = mkOption {
        type = types.string;
        default = "/var/lib/bacula-sd/";
        description = ''
          Bacula Storage Daemon workdir. It's used in every `Storage` definition only if `WorkingDirectory` is not specifically provided.
This way in default way it handles all the permissions and directory creation.
        '';
      };

      director = mkOption {
        default = {};
        description = ''
          This option defines Director resources in Bacula Storage Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };

      device = mkOption {
        default = {};
        description = ''
          This option defines Device resources in Bacula Storage Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      storage = mkOption {
        default = { };
        description = ''
          This option defines Storage resources in Bacula Storage Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };

      messages = mkOption {
        default = { 
                    Standard = {
		      syslog = "all, !skipped, !restored";
                    };
                  };
        description = ''
          This option defines Messages resources in Bacula Storage Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
    };

    services.bacula-dir = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable Bacula Director Daemon.
        '';
      };

      workdir = mkOption {
        type = types.string;
        default = "/var/lib/bacula-dir/";
        description = ''
          Bacula Director Daemon workdir. It's used in every `Director` definition only if `WorkingDirectory` is not specifically provided.
This way in default way it handles all the permissions and directory creation.
        '';
      };

      director = mkOption {
        default = {};
        description = ''
          This option defines Director resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };

      job = mkOption {
        default = {};
        description = ''
          This option defines Job resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };

      jobDefs = mkOption {
        default = {};
        description = ''
          This option defines JobDef resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      schedule = mkOption {
        default = {};
        description = ''
          This option defines Schedule resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      fileSet = mkOption {
        default = {};
        description = ''
          This option defines FileSet resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      client = mkOption {
        default = {};
        description = ''
          This option defines Client resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      storage = mkOption {
        default = {};
        description = ''
          This option defines Director resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      pool = mkOption {
        default = {};
        description = ''
          This option defines Pool resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      counter = mkOption {
        default = {};
        description = ''
          This option defines Counter resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      console = mkOption {
        default = {};
        description = ''
          This option defines Console resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
 
      catalog = mkOption {
        default = {
                    "PostgreSQL" = {
                      dbname = "bacula";
                      user = "bacula";
		    };
	          };
        description = ''
          This option defines Catalog resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };
      messages = mkOption {
        default = { 
                    Standard = {
		      syslog = "all, !skipped, !restored";
                    };
                  };
        description = ''
          This option defines Messages resources in Bacula Director Daemon.
        '';
        type = with types; attrsOf types.unspecified;
      };

    };
  };

  config = mkIf (fd_cfg.enable || sd_cfg.enable || dir_cfg.enable) {
    systemd.services.bacula-fd = mkIf fd_cfg.enable {
      after = [ "network.target" ];
      description = "Bacula File Daemon";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.bacula ];
      serviceConfig = {
        ExecStart = "${pkgs.bacula}/sbin/bacula-fd -f -u root -g bacula -c ${fd_conf}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        LogsDirectory = "bacula";
        StateDirectory = "bacula";
      };
      preStart = ''
        mkdir -p "${fd_cfg.workdir}"
        chown -R root:bacula "${fd_cfg.workdir}"
      '';
    };

    systemd.services.bacula-sd = mkIf sd_cfg.enable {
      after = [ "network.target" ];
      description = "Bacula Storage Daemon";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.bacula ];
      serviceConfig = {
        ExecStart = "${pkgs.bacula}/sbin/bacula-sd -f -u bacula -g bacula -c ${sd_conf}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        LogsDirectory = "bacula";
        StateDirectory = "bacula";
      };
      preStart = ''
        mkdir -p "${sd_cfg.workdir}"
        chown -R root:bacula "${sd_cfg.workdir}"
      '';
    };

    services.postgresql.enable = dir_cfg.enable == true;

    systemd.services.bacula-dir = mkIf dir_cfg.enable {
      after = [ "network.target" "postgresql.service" ];
      description = "Bacula Director Daemon";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.bacula pkgs.su ];
      serviceConfig = {
        ExecStart = "${pkgs.bacula}/sbin/bacula-dir -f -u bacula -g bacula -c ${dir_conf}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        LogsDirectory = "bacula";
        StateDirectory = "bacula";
      };
      preStart = ''
        mkdir -p "${dir_cfg.workdir}"
        chown -R bacula:bacula "${dir_cfg.workdir}"

        SUDO="${pkgs.sudo}/bin/sudo -u ${config.services.postgresql.superUser}"

        if ! test -e "${libDir}/db-created"; then
            $SUDO ${pkgs.postgresql}/bin/createuser --no-superuser --no-createdb --no-createrole bacula
            #${pkgs.postgresql}/bin/createdb --owner bacula bacula

            # populate DB
            ${pkgs.bacula}/etc/create_bacula_database postgresql
            ${pkgs.bacula}/etc/make_bacula_tables postgresql
            ${pkgs.bacula}/etc/grant_bacula_privileges postgresql
            touch "${libDir}/db-created"
        else
            ${pkgs.bacula}/etc/update_bacula_tables postgresql || true
        fi
      '';
    };

    environment.systemPackages = [ pkgs.bacula ];

    users.users.bacula = {
      group = "bacula";
      uid = config.ids.uids.bacula;
      home = "${libDir}";
      createHome = true;
      description = "Bacula Daemons user";
      shell = "${pkgs.bash}/bin/bash";
    };

    users.groups.bacula.gid = config.ids.gids.bacula;
  };
}

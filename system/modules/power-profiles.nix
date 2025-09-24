{ config, lib, pkgs, ... }:
let
  cfg = config.power.profiles;

  powerProfileScript = pkgs.writeShellScriptBin "power-profile" ''
    #!/usr/bin/env bash
    set -euo pipefail

    PROFILE="''${1:-}"

    usage() {
      echo "Usage: power-profile set <quiet|balanced|performance> | status | apply-default" >&2
      exit 1
    }

    require_root() {
      if [[ "$(id -u)" -ne 0 ]]; then
        echo "This command must run as root (use sudo)." >&2
        exit 1
      fi
    }

    set_cpu() {
      local profile="$1"

      local gov="schedutil"
      local turbo="on"
      case "$profile" in
        quiet)
          gov="powersave"; turbo="off" ;;
        balanced)
          gov="schedutil"; turbo="on" ;;
        performance)
          gov="performance"; turbo="on" ;;
      esac

      # Determine available governors and pick a valid one with fallback
      local avail_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
      local avail=""
      [[ -r "$avail_file" ]] && avail="$(cat "$avail_file" 2>/dev/null)"
      choose_gov() {
        local desired="$1"
        case " $avail " in
          *" $desired "*) echo "$desired";;
          *" schedutil "*) echo schedutil;;
          *" ondemand "*) echo ondemand;;
          *" conservative "*) echo conservative;;
          *" powersave "*) echo powersave;;
          *" performance "*) echo performance;;
          *) echo "$desired";;
        esac
      }
      local chosen_gov
      chosen_gov="$(choose_gov "$gov")"

      # Set governor for all CPUs
      for gfile in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [[ -w "$gfile" ]] && echo "$chosen_gov" >"$gfile" || true
      done

      # Toggle turbo for Intel (intel_pstate)
      if [[ -e /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        if [[ "$turbo" == "on" ]]; then
          echo 0 >/sys/devices/system/cpu/intel_pstate/no_turbo || true
        else
          echo 1 >/sys/devices/system/cpu/intel_pstate/no_turbo || true
        fi
      fi

      # Toggle turbo/boost for AMD
      if [[ -e /sys/devices/system/cpu/cpufreq/boost ]]; then
        if [[ "$turbo" == "on" ]]; then
          echo 1 >/sys/devices/system/cpu/cpufreq/boost || true
        else
          echo 0 >/sys/devices/system/cpu/cpufreq/boost || true
        fi
      fi
    }

    set_gpu() {
      local profile="$1"
      if ! command -v nvidia-smi >/dev/null 2>&1; then
        return 0
      fi

      # Enable persistence mode to keep settings
      nvidia-smi -pm 1 >/dev/null 2>&1 || true

      # Determine default and supported limits (best-effort)
      local default_pl max_pl min_pl cur_pl
      default_pl=$(nvidia-smi -q -d POWER 2>/dev/null | awk '/Default Power Limit/{print $5; exit}')
      max_pl=$(nvidia-smi -q -d POWER 2>/dev/null | awk '/Max Power Limit/{print $5; exit}')
      min_pl=$(nvidia-smi -q -d POWER 2>/dev/null | awk '/Min Power Limit/{print $5; exit}')
      cur_pl=$(nvidia-smi -q -d POWER 2>/dev/null | awk '/Power Limit/{print $5; exit}')

      # Decide a target power limit in watts for laptop dGPUs
      # If we cannot detect, skip quietly.
      local target=""
      case "$profile" in
        quiet)
          # Prefer near-min; fall back to 45W if unknown
          if [[ -n "$min_pl" ]]; then target="$min_pl"; else target="45"; fi ;;
        balanced)
          # Midpoint between min and default (or 65W fallback)
          if [[ -n "$min_pl" && -n "$default_pl" ]]; then
            target=$(( (min_pl + default_pl) / 2 ))
          else
            target="65"
          fi ;;
        performance)
          # Use default or max if available
          if [[ -n "$default_pl" ]]; then target="$default_pl";
          elif [[ -n "$max_pl" ]]; then target="$max_pl"; fi ;;
      esac

      if [[ -n "$target" ]]; then
        nvidia-smi -pl "$target" >/dev/null 2>&1 || true
      fi
    }

    show_status() {
      echo "CPU governor(s):"
      local gfiles=(/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor)
      if [[ -e "''${gfiles[0]:-}" ]]; then
        for gfile in "''${gfiles[@]}"; do
          # parent of cpufreq dir is e.g. cpu0
          cpu=$(basename "$(dirname "$(dirname "$gfile")")")
          gov=$(cat "$gfile" 2>/dev/null || echo "?")
          echo "  $cpu: $gov"
        done
      else
        echo "  cpufreq not available"
      fi

      if [[ -e /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        nt=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
        echo "Intel turbo: $([[ "$nt" == "0" ]] && echo on || echo off)"
      elif [[ -e /sys/devices/system/cpu/cpufreq/boost ]]; then
        b=$(cat /sys/devices/system/cpu/cpufreq/boost)
        echo "CPU boost: $([[ "$b" == "1" ]] && echo on || echo off)"
      fi

      if command -v nvidia-smi >/dev/null 2>&1; then
        # Try concise CSV first
        local line
        line=$(nvidia-smi --query-gpu=name,power.draw,power.limit --format=csv,noheader,nounits 2>/dev/null | head -n1 || true)
        if [[ -n "$line" ]]; then
          # name,draw,limit
          local name draw limit
          IFS="," read -r name draw limit <<<"$line"
          # trim spaces
          name="''${name## }"; name="''${name%% }"
          draw="''${draw## }"; draw="''${draw%% }"
          limit="''${limit## }"; limit="''${limit%% }"
          echo "NVIDIA: $name, ''${draw}W / ''${limit}W"
        else
          echo "NVIDIA:"
          nvidia-smi -q -d POWER | sed -n '/Power Readings:/,$p' | sed -n '1,12p' || true
        fi
      fi
    }

    apply_profile() {
      local profile="$1"
      require_root
      case "$profile" in
        quiet|balanced|performance) ;;
        *)
          usage ;;
      esac
      set_cpu "$profile"
      set_gpu "$profile"
      echo "Applied power profile: $profile"
    }

    case "$PROFILE" in
      set)
        shift || true
        [[ $# -ge 1 ]] || usage
        apply_profile "$1"
        ;;
      status)
        show_status
        ;;
      apply-default)
        apply_profile "${cfg.defaultProfile}"
        ;;
      *)
        usage
        ;;
    esac
  '';
in
{
  options.power.profiles = {
    enable = lib.mkEnableOption "custom power profile toggles" // { default = true; };
    defaultProfile = lib.mkOption {
      type = lib.types.enum [ "quiet" "balanced" "performance" ];
      default = "balanced";
      description = "Default profile applied at boot.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ powerProfileScript ];

    systemd.services."power-profile-apply" = {
      description = "Apply default power profile";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${powerProfileScript}/bin/power-profile apply-default";
      };
    };

    # Quick entrypoints: sudo systemctl start power-profile@quiet
    systemd.services."power-profile@" = {
      description = "Apply power profile %i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${powerProfileScript}/bin/power-profile set %i";
      };
    };
  };
}

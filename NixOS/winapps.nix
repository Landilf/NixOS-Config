{ config, pkgs, ... }:

let
  # Создаем скрипт-обертку для FreeRDP, который принудительно запускает его в XWayland
  freerdp-x11 = pkgs.writeShellScriptBin "xfreerdp-x11" ''
    # WinApps redirects stdout/stderr to /dev/null, so log directly to a file for debugging.
    LOG_DIR="$HOME/.local/share/winapps"
    LOG_FILE="$LOG_DIR/xfreerdp-x11.log"
    mkdir -p "$LOG_DIR"

	    # RemoteApps have been observed to crash in the X11 frontend (xfreerdp) under XWayland
	    # with errors like "BadMatch (X_CopyArea)". Prefer the newer SDL client for RemoteApps.
    is_remoteapp=0
    for arg in "$@"; do
      case "$arg" in
        /app:program:*)
          is_remoteapp=1
          ;;
      esac
    done

		    # WinApps itself may prepend its own FreeRDP to PATH. Use absolute paths to ensure
		    # we actually run the system FreeRDP (we intentionally install it from nixos-unstable).
		    xfreerdp_bin="/run/current-system/sw/bin/xfreerdp"
		    sfreerdp_bin="/run/current-system/sw/bin/sfreerdp"
		    if [ ! -x "$xfreerdp_bin" ]; then
		      xfreerdp_bin="$(command -v xfreerdp || true)"
		    fi
		    if [ ! -x "$sfreerdp_bin" ]; then
		      sfreerdp_bin="$(command -v sfreerdp || true)"
		    fi

		    freerdp_cmd="$xfreerdp_bin"
		    if [ "$is_remoteapp" -eq 1 ]; then
		      freerdp_cmd="$sfreerdp_bin"
		    else
		      export WAYLAND_DISPLAY=
		      export GDK_BACKEND=x11
		      export QT_QPA_PLATFORM=xcb
		    fi

		    # SDL clients may pick Vulkan by default; on some Hyprland/NVIDIA setups this can result
		    # in a black window. Force a more compatible renderer.
		    if [ "$(basename "$freerdp_cmd")" != "xfreerdp" ]; then
		      export SDL_RENDER_DRIVER="opengl"
		    fi

		    # Filter X11-specific args when using non-xfreerdp clients.
		    filtered_args=()
		    if [ "$(basename "$freerdp_cmd")" != "xfreerdp" ]; then
		      for arg in "$@"; do
		        case "$arg" in
	          # WinApps always passes an empty domain as /d: when RDP_DOMAIN is unset.
	          # Some servers/clients behave oddly with an explicit empty domain; drop it.
	          /d:)
	            continue
	            ;;
	          /wm-class:*)
	            continue
	            ;;
	          # For RemoteApps, WinApps packs icon/name into the /app argument.
	          # Some FreeRDP frontends/servers are picky here; keep only essentials.
	          /app:program:*)
	            arg="$(echo "$arg" | sed -E 's/,icon:[^,]*//g; s/,name:[^,]*//g')"
	            ;;
	        esac
	        filtered_args+=("$arg")
		      done
		    else
		      filtered_args=("$@")
		    fi

    {
      echo "==== $(date -Is) ===="
      printf "%s" "$freerdp_cmd"
      for arg in "''${filtered_args[@]}"; do
        case "$arg" in
          /p:*|/password:*)
            printf " %q" "/p:REDACTED"
            ;;
          *)
            printf " %q" "$arg"
            ;;
        esac
      done
      echo
    } >>"$LOG_FILE"

    exec "$freerdp_cmd" "''${filtered_args[@]}" >>"$LOG_FILE" 2>&1
  '';
in
{
  xdg.configFile."winapps/winapps.conf".text = ''
    # [WINDOWS USERNAME]
    RDP_USER="landilf"

    # [WINDOWS PASSWORD]
    RDP_PASS="2891"

    # [WINDOWS IPV4 ADDRESS]
    RDP_IP="127.0.0.1"

    # [WINAPPS BACKEND]
    WAFLAVOR="docker"

    # [TIMEOUTS]
    RDP_TIMEOUT=60
    APP_SCAN_TIMEOUT=120

    # [ADDITIONAL FREERDP FLAGS]
    HIDEF="off"
    #
	    # NOTE: FreeRDP flags apply to both full desktop ("windows") and RemoteApps.
	    # Some flags (notably certain /gfx:* modes) can break RemoteApps while full desktop still works.
	    # Keep "safe defaults" in RDP_FLAGS and put aggressive tuning into RDP_FLAGS_WINDOWS.
	    # Disable Kerberos auth: on machines without a default realm configured it can break NLA/SSPI flows.
	    RDP_FLAGS="/cert:tofu /auth-pkg-list:!kerberos"
	    # Full desktop session can afford extra devices and tuning.
	    RDP_FLAGS_WINDOWS="/sound /microphone /drive:home,/home/landilf /gfx:rfx /network:lan /bpp:32"
	    # RemoteApps: keep it minimal and stable.
	    RDP_FLAGS_NON_WINDOWS="/network:lan /bpp:32"

    FREERDP_COMMAND="${freerdp-x11}/bin/xfreerdp-x11"
  '';
}

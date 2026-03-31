{ pkgs, config, inputs, ... }:

let
  # disable the annoying floating icon with camera and mic when on a call
  disableWebRtcIndicator = ''
    #webrtcIndicator {
      display: none;
    }
  '';

  userChrome = disableWebRtcIndicator;

  # ~/.mozilla/firefox/PROFILE_NAME/prefs.js | user.js
  settings = {
    # Compact UI - thin tabs and search bar
    "browser.uidensity" = 1;

    # Disable Pocket
    "extensions.pocket.api" = "";
    "extensions.pocket.enabled" = false;
    "extensions.pocket.site" = "";
    "extensions.pocket.oAuthConsumerKey" = "";

    # Disable fullscreen animation and ESC warning
    "full-screen-api.transition-duration.enter" = "0";
    "full-screen-api.transition-duration.leave" = "0";
    "full-screen-api.warning.timeout" = 0;

    # Privacy - Do Not Track
    "privacy.trackingprotection.enabled" = true;
    "privacy.donottrackheader.enabled" = true;

    # Disable telemetry and crash reports
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.cachedClientID" = "";
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.hybridContent.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.previousBuildID" = "";
    "toolkit.telemetry.reportingpolicy.firstRun" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.server_owner" = "";
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "datareporting.healthreport.infoURL" = "";
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.policy.firstRunURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "browser.tabs.crashReporting.email" = false;
    "browser.tabs.crashReporting.emailMe" = false;
    "breakpad.reportURL" = "";
    "security.ssl.errorReporting.automatic" = false;
    "toolkit.crashreporter.infoURL" = "";
    "network.allow-experiments" = false;
    "dom.ipc.plugins.reportCrashURL" = false;
    "dom.ipc.plugins.flash.subprocess.crashreporter.enabled" = false;
  };
in
{
  programs.firefox = {
    enable = true;

    package = inputs.nixpkgs-firefox.legacyPackages.${pkgs.system}.firefox-beta;

    profiles = {
      default = {
        id = 0;
        inherit settings userChrome;
      };
    };

    policies = {
      ExtensionSettings = {
        "*" = {
          installation_mode = "allowed";
          run_in_private_windows = "allow";
        };
      };
    };
  };
}

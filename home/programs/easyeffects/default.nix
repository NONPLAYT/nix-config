{ lib
, pkgs
, ...
}:

let
  easyeffectsrc = pkgs.writeText "easyeffectsrc" ''
    [StreamInputs]
    inputDevice=
    visiblePage=pluginsPage

    [StreamOutputs]
    outputDevice=
    plugins=
    visiblePage=pluginsPage

    [Window]
    height=668
    showTrayIcon=false
    width=1251
  '';

  ladspaPath = "${pkgs.deepfilternet}/lib/ladspa";
in
{
  home.packages = [ pkgs.deepfilternet ];
  home.sessionVariables.LADSPA_PATH = ladspaPath;
  systemd.user.sessionVariables.LADSPA_PATH = ladspaPath;

  services.easyeffects = {
    enable = true;

    preset = "fifine-am8";

    extraPresets.fifine-am8.input = {
      blocklist = [ ];

      plugins_order = [
        # "stereo_tools#0"
        "rnnoise#0"
        "deepfilternet#0"
        "gate#0"
        "equalizer#0"
        "compressor#0"
        "deesser#0"
        "limiter#0"
      ];

      "stereo_tools#0" = {
        bypass = false;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        mode = "LR > LL (Mono Left Channel)";
        "balance-in" = 0.0;
        "balance-out" = 0.0;
        slev = 1.0;
        sbal = 0.0;
        mlev = 1.0;
        mpan = 0.0;
        "stereo-base" = 0.0;
        delay = 0.0;
        "sc-level" = 1.0;
        "stereo-phase" = 0.0;
        softclip = false;
        mutel = false;
        muter = false;
        phasel = false;
        phaser = false;
      };

      "rnnoise#0" = {
        bypass = false;
        "enable-vad" = false;
        "input-gain" = 6.0;
        "output-gain" = 0.0;
        "model-name" = "";
        "use-standard-model" = true;
        release = 20.0;
        "vad-thres" = 30.0;
        wet = 0.0;
      };

      "deepfilternet#0" = {
        bypass = false;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        "attenuation-limit" = 80.0;
        "min-processing-threshold" = -15.0;
        "max-erb-processing-threshold" = 30.0;
        "max-df-processing-threshold" = 20.0;
        "min-processing-buffer" = 0;
        "post-filter-beta" = 0.02;
      };

      "gate#0" = {
        bypass = false;
        attack = 5.0;
        release = 300.0;
        "curve-threshold" = -42.0;
        "curve-zone" = -2.0;
        hysteresis = true;
        "hysteresis-threshold" = -3.0;
        "hysteresis-zone" = -1.0;
        reduction = -12.0;
        makeup = 0.0;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        "hpf-mode" = "Off";
        "hpf-frequency" = 10.0;
        "lpf-mode" = "Off";
        "lpf-frequency" = 20000.0;
        dry = -80.01;
        wet = -1.0;
        "stereo-split" = false;
        "input-to-link" = 0.0;
        "input-to-sidechain" = 0.0;
        "link-to-input" = 0.0;
        "link-to-sidechain" = 0.0;
        "sidechain-to-input" = 0.0;
        "sidechain-to-link" = 0.0;
        sidechain = {
          lookahead = 0.0;
          mode = "RMS";
          preamp = 0.0;
          reactivity = 10.0;
          source = "Middle";
          "stereo-split-source" = "Left/Right";
          type = "Internal";
        };
      };

      "equalizer#0" =
        let
          bands = {
            band0 = {
              type = "Hi-pass";
              mode = "RLC (BT)";
              frequency = 100.0;
              gain = 0.0;
              q = 0.7;
              slope = "x2";
              width = 4.0;
              mute = false;
              solo = false;
            };
            band1 = {
              type = "Bell";
              mode = "RLC (MT)";
              frequency = 220.0;
              gain = -3.0;
              q = 0.8;
              slope = "x1";
              width = 4.0;
              mute = false;
              solo = false;
            };
            band2 = {
              type = "Bell";
              mode = "BWC (MT)";
              frequency = 400.0;
              gain = -2.0;
              q = 1.2;
              slope = "x2";
              width = 4.0;
              mute = false;
              solo = false;
            };
            band3 = {
              type = "Bell";
              mode = "BWC (BT)";
              frequency = 3200.0;
              gain = 3.0;
              q = 0.9;
              slope = "x2";
              width = 4.0;
              mute = false;
              solo = false;
            };
            band4 = {
              type = "Hi-shelf";
              mode = "LRX (MT)";
              frequency = 8000.0;
              gain = 0.0;
              q = 0.7;
              slope = "x1";
              width = 4.0;
              mute = false;
              solo = false;
            };
          };
        in
        {
          bypass = false;
          "input-gain" = 0.0;
          "output-gain" = 0.0;
          mode = "IIR";
          "num-bands" = 5;
          balance = 0.0;
          "pitch-left" = 0.0;
          "pitch-right" = 0.0;
          "split-channels" = false;
          left = bands;
          right = bands;
        };

      "compressor#0" = {
        bypass = false;
        mode = "Downward";
        attack = 15.0;
        release = 200.0;
        ratio = 3.0;
        knee = -6.0;
        threshold = -24.0;
        makeup = 6.0;
        "release-threshold" = -40.0;
        "boost-amount" = 0.0;
        "boost-threshold" = -72.0;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        "hpf-mode" = "Off";
        "hpf-frequency" = 10.0;
        "lpf-mode" = "Off";
        "lpf-frequency" = 20000.0;
        dry = -80.01;
        wet = 0.0;
        "stereo-split" = false;
        "input-to-link" = 0.0;
        "input-to-sidechain" = 0.0;
        "link-to-input" = 0.0;
        "link-to-sidechain" = 0.0;
        "sidechain-to-input" = 0.0;
        "sidechain-to-link" = 0.0;
        sidechain = {
          lookahead = 0.0;
          mode = "RMS";
          preamp = 0.0;
          reactivity = 10.0;
          source = "Middle";
          "stereo-split-source" = "Left/Right";
          type = "Feed-forward";
        };
      };

      "deesser#0" = {
        bypass = false;
        mode = "Split";
        detection = "RMS";
        "f1-freq" = 4000.0;
        "f1-level" = -6.0;
        "f2-freq" = 8000.0;
        "f2-level" = -6.0;
        "f2-q" = 1.5;
        threshold = -18.0;
        ratio = 3.0;
        laxity = 15;
        makeup = 0.0;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        "sc-listen" = false;
      };

      "limiter#0" = {
        bypass = false;
        mode = "Herm Wide";
        threshold = -1.5;
        attack = 2.0;
        release = 5.0;
        lookahead = 2.0;
        oversampling = "None";
        dithering = "16bit";
        "gain-boost" = false;
        alr = false;
        "alr-attack" = 5.0;
        "alr-knee" = 0.0;
        "alr-release" = 50.0;
        "input-gain" = 0.0;
        "output-gain" = 0.0;
        "stereo-link" = 100.0;
        "sidechain-type" = "Internal";
        "sidechain-preamp" = 0.0;
        "input-to-link" = 0.0;
        "input-to-sidechain" = 0.0;
        "link-to-input" = 0.0;
        "link-to-sidechain" = 0.0;
        "sidechain-to-input" = 0.0;
        "sidechain-to-link" = 0.0;
      };
    };
  };

  home.activation.easyeffects = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/easyeffects/db"
    if [ ! -f "$HOME/.config/easyeffects/db/easyeffectsrc" ]; then
      cp ${easyeffectsrc} "$HOME/.config/easyeffects/db/easyeffectsrc"
      chmod u+w "$HOME/.config/easyeffects/db/easyeffectsrc"
    fi
  '';
}

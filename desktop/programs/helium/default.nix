{ ... }:

{
  programs.chromium = {
    enable = true;

    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      "fhnndedhnphdfnhnalkjiijkeddaoafl" # chatterino+
      "mafcicncghogpdpaieifglifaagndbni" # rogold
      "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock
    ];

    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";

    extraOpts = {
      DefaultSearchProviderName = "DuckDuckGo";
      DefaultSearchProviderKeyword = "ddg";

      # --- passwords/autofill: off (bitwarden) ---
      PasswordManagerEnabled = false;
      PasswordLeakDetectionEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      # --- telemetry/sync: off ---
      MetricsReportingEnabled = false;
      BrowserSignin = 0;
      SyncDisabled = true;

      # --- network privacy ---
      NetworkPredictionOptions = 2;

      # --- ui ---
      DefaultBrowserSettingEnabled = false;
      PrintHeaderFooter = false;

      # --- languages ---
      ForcedLanguages = [ "ru-RU" "ru" "en-US" "en" ];
      SpellcheckEnabled = true;
      SpellcheckLanguage = [ "ru" "en-US" ];
    };
  };
}

{
  projectRootFile = "LICENSE";

  programs.nixfmt.enable = true;
  programs.nixf-diagnose.enable = true;
  programs.actionlint.enable = true;
  programs.typos.enable = true;

  programs.yamlfmt = {
    enable = true;
    settings.formatter = {
      retain_line_breaks = true;
    };
  };

}

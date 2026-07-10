{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    awscli2
    bashInteractive
    curl
    git
    jq
    nodejs_22
    playwright-driver.browsers
    ripgrep
  ];

  PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs.playwright-driver.browsers}/chromium-1217/chrome-linux64/chrome";
  PLAYWRIGHT_CHROMIUM_HEADLESS_SHELL_PATH = "${pkgs.playwright-driver.browsers}/chromium_headless_shell-1217/chrome-headless-shell-linux64/chrome-headless-shell";
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";

  shellHook = ''
    echo "sethcharleston.com dev shell"
    echo "Node: $(node --version)"
    echo "npm:  $(npm --version)"
    echo "AWS:  $(aws --version 2>&1)"
    echo "Playwright browsers: $PLAYWRIGHT_BROWSERS_PATH"
    echo "Chromium: $PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH"
  '';
}

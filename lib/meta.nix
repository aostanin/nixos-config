{
  lib,
  pkgs,
}: rec {
  filterAvailable = builtins.filter (packageAvailable pkgs.stdenv.hostPlatform);

  brokenOn = cond: pkg:
    pkg.overrideAttrs (old: {
      meta = (old.meta or {}) // {broken = (old.meta.broken or false) || cond;};
    });

  brokenOnDarwin = brokenOn pkgs.stdenv.hostPlatform.isDarwin;

  packageAvailable = platform: pkg: let
    name = builtins.tryEval (pkg.name or pkg.pname or "unknown");
    pkgName =
      if name.success
      then name.value
      else "unknown";
    meta = builtins.tryEval pkg.meta;
    reason =
      if !meta.success
      then "not available on ${platform.system}"
      else if meta.value.broken or false
      then "broken"
      else if !(lib.meta.availableOn platform pkg)
      then "not supported on ${platform.system}"
      else if !(builtins.tryEval pkg.outPath).success
      then "dependency not available on ${platform.system}"
      else null;
  in
    if reason != null
    then lib.warn "skipping ${pkgName}: ${reason}" false
    else true;
}

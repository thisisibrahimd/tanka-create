local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

{
  common:: {
    // Mirrors: default.name
    name::
      local base = if $._config.nameOverride != '' then $._config.nameOverride else $._library.name;
      if std.length(base) > 63 then std.substr(base, 0, 63) else base,

    // Mirrors: default.fullname
    // Tanka has no .Release.Name — environments override fullnameOverride
    fullname::
      if $._config.fullnameOverride != '' then
        local v = $._config.fullnameOverride;
        if std.length(v) > 63 then std.substr(v, 0, 63) else v
      else
        $.common.name,

    // Mirrors: default.labels
    labels:: {
      'app.kubernetes.io/name': $.common.name,
      'app.kubernetes.io/instance': $.common.name,
      'app.kubernetes.io/managed-by': 'tanka',
    } + (
      if $._config.image.tag != '' then {
        'app.kubernetes.io/version': $._config.image.tag,
      } else {}
    ),

    // Mirrors: default.selectorLabels
    selectorLabels:: {
      'app.kubernetes.io/name': $.common.name,
      'app.kubernetes.io/instance': $.common.name,
    },

    // Mirrors: default.serviceAccountName
    serviceAccountName::
      if $._config.serviceAccount.create then
        if $._config.serviceAccount.name != '' then
          $._config.serviceAccount.name
        else
          $.common.fullname
      else
        if $._config.serviceAccount.name != '' then
          $._config.serviceAccount.name
        else
          $._library.name,
  },
}

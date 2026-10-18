{
  _images+:: {
    app: if $._config.image.tag != ''
      then '%s:%s' % [$._config.image.repository, $._config.image.tag]
      else $._config.image.repository,
  },
}

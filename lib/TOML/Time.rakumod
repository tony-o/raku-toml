unit class TOML::Time;
has int $.hour;
has int $.minute;
has     $.second;
has     $.offset = 0;
method gist {
    sprintf('%02d:%02d:%0.3f', $!hour, $!minute, $!second)
  ~ ($.offset == 0
      ?? 'Z'
      !! sprintf('%s%02d:%02d',
                 $.offset < 0 ?? '-' !! '+',
                 $.offset.floor,
                 (60 * ($.offset - $.offset.floor).abs)));
}

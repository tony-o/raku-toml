unit class TOML::Time;
has int $.hour;
has int $.minute;
has     $.second;
has     $.offset = 0;

multi method new($hour where 0 <= * <= 23,
                 $minute where 0 <= * <= 59,
                 $second where 0 <= * < 60,
                 $offset? where -43200 <= * <= 50400 = 0) {
  self.bless(:$hour,:$minute,:$second,:$offset);
}

multi method new(:$hour where 0 <= * <= 23,
                 :$minute where 0 <= * <= 59,
                 :$second where 0 <= * < 60,
                 :$offset? where -43200 <= * <= 50400 = 0) {
  self.bless(:$hour,:$minute,:$second,:$offset);
}

method gist {
    sprintf('%02d:%02d:%0.3f', $!hour, $!minute, $!second)
  ~ ($.offset == 0
      ?? 'Z'
      !! sprintf('%s%02d:%02d',
                 $.offset < 0 ?? '-' !! '+',
                 ($.offset / 3600).floor,
                 ($.offset % 3600) / 60 ));
}

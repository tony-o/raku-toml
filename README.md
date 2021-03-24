# TOML

A TOML 1.0.0 compliant serializer/deserializer.

## Usage

Parsing TOML

```rakudo
use TOML;

my $config = from-toml("config.toml".IO.slurp);
# use $config like any ol' hash
```

Generating TOML

```rakudo
use TOML;

my $config = {
  bands => ['green day',
            'motorhead',
            't swift',],
  favorite => 'little big',
};

my $toml-config = to-toml($config);
#favorite = "little big"
#bands = ["green day",
#         "motorhead",
#         "t swift"]
```

## License

[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

## Authors

@[tony-o](https://github.com/tony-o)

## Credits

The tests here use @[BurntSushi](https://github.com/BurntSushi)'s toml-tests.

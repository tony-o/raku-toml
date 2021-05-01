#!/usr/bin/env raku

use lib 'lib';
use TOML;
use TOML::Grammar;
use TOML::Actions;
use Bench;

my $b = Bench.new;

my $toml = to-toml({:Build($[{:module("Zef::Service::Shell::DistributionBuilder"), :short-name("default-builder")}, {:module("Zef::Service::Shell::LegacyBuild"), :short-name("legacy-builder")}]), :ConfigVersion("1"), :DefaultCUR($["auto"]), :Extract($[{:comment("used to checkout (extract) specific tags/sha1/commit/branch from a git repo"), :module("Zef::Service::Shell::git"), :short-name("git")}, {:comment("if this goes before git then git wont be able to extract/checkout local paths because this reaches it first :("), :module("Zef::Service::FetchPath"), :short-name("path")}, {:module("Zef::Service::Shell::tar"), :short-name("tar")}, {:module("Zef::Service::Shell::p5tar"), :short-name("p5tar")}, {:module("Zef::Service::Shell::unzip"), :short-name("unzip")}, {:module("Zef::Service::Shell::PowerShell::unzip"), :short-name("psunzip")}]), :Fetch($[{:module("Zef::Service::Shell::git"), :options(${:scheme("https")}), :short-name("git")}, {:module("Zef::Service::FetchPath"), :short-name("path")}, {:module("Zef::Service::Shell::curl"), :short-name("curl")}, {:module("Zef::Service::Shell::wget"), :short-name("wget")}, {:module("Zef::Service::Shell::PowerShell::download"), :short-name("pswebrequest")}]), :Install($[{:enabled(1), :module("Zef::Service::InstallRakuDistribution"), :short-name("install-raku-dist")},]), :License(${:blacklist($[]), :whitelist("*")}), :Report($[{:enabled(0), :module("Zef::Service::FileReporter"), :short-name("file-reporter")},]), :Repository($[{:enabled(1), :module("Zef::Repository::Ecosystems"), :options(${:auto-update(1), :mirrors($["http://360.zef.pm/"]), :name("fez"), :uses-path(Bool::True)}), :short-name("fez")}, {:enabled(1), :module("Zef::Repository::LocalCache"), :options(${}), :short-name("cached")}, {:enabled(1), :module("Zef::Repository::Ecosystems"), :options(${:auto-update(1), :mirrors($["https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json", "https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan.json", "git://github.com/ugexe/Perl6-ecosystems.git"]), :name("cpan")}), :short-name("cpan")}, {:enabled(1), :module("Zef::Repository::Ecosystems"), :options(${:auto-update(1), :mirrors($["https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c1.json", "git://github.com/ugexe/Perl6-ecosystems.git", "http://ecosystem-api.p6c.org/projects1.json"]), :name("p6c")}), :short-name("p6c")}]), :RootDir("\$*HOME/.zef"), :StoreDir("\$*HOME/.zef/store"), :TempDir("\$*HOME/.zef/tmp"), :Test($[{:comment("Raku TAP::Harness adapter"), :module("Zef::Service::TAP"), :short-name("tap-harness")}, {:module("Zef::Service::Shell::prove"), :short-name("prove")}, {:module("Zef::Service::Shell::Test"), :short-name("raku-test")}])});

$b.cmpthese(1000, {
  nqp     => sub {
    from-toml($toml);
  },
  grammar => sub {
    TOML::Grammar.parse($toml);
  },
  actions => sub {
    TOML::Grammar.parse($toml, :actions(TOML::Actions.new));
  },
});

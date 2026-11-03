# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-11-03

### Added

- The record types are defined. libgtop names them `glibtop_proc_uid`,
  `glibtop_mountentry` and so on, all lowercase, and the loader const_set those
  names directly — which warns `rb_define_const: invalid name` and defines
  nothing. The namespace had 372 constants, 36 functions and not one class.
  They are now CamelCased with the `glibtop_` prefix dropped, so
  `glibtop_proc_uid` is `GTop::ProcUid`, giving 42 record classes with readable
  fields.

### Changed

- The README now leads with the limitation this gem cannot fix: **the functions
  are not callable.** Every libgtop function takes its result struct as the
  first argument, and GObjectIntrospection resolves an argument's class from
  the raw GI name via `mod.const_defined?("glibtop_proc_uid")`, which raises
  `NameError: wrong constant name` regardless of what this gem names the class.
  Found when console-rb tried to read process statistics through it. A Ruby
  port needs `/proc` directly; fixing this means changing `resolve_class` in
  ruby-gnome, not here.

## [1.0.0] - 2026-11-03

### Added

- `GTop`, defined from the `GTop-2.0.typelib` GObject Introspection typelib at require
  time, giving libgtop, reading process and system statistics portably. `GTop::Loader` is a `GObjectIntrospection::Loader`
  subclass, so the binding is the whole namespace rather than a hand-written
  subset, and it does not drift as the library gains API. The typelib version
  is `2.0`, read off the package rather than inferred -- these are not
  guessable, and guessing is how a loader silently fails.
- A dev shell (`flake.nix`) pinning the library and everything its typelib
  declares from one nixpkgs, and CI that runs the suite inside it. The
  environment is the hard part of an introspection binding: a typelib built
  against a different glib than the `gobject-introspection` gem registers GIO
  twice in the process and fails with
  `cannot register existing type 'GTlsCertificate'`.
- A README naming the distribution package that carries the typelib, and a
  worked `flake.nix` listing every nix dependency. That list is the gem's own
  search path, so it cannot drift from what the dev shell uses.
- Pure Ruby: no extension, no Cargo workspace, no per-platform gem. Installing
  does still compile C, because `glib2` and `gobject-introspection` are native
  extensions built against glib, but this gem adds no build step of its own and
  those two are what every ruby-gnome application already has via `gtk4`.

# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "libgtop"

describe GTop do
  it "defines the namespace from the typelib" do
    # Not an arbitrary number: it is the point of the loader. A hand-written
    # binding exposes what someone got round to wrapping; this exposes what the
    # library has. A drop to single digits means the loader half-ran.
    expect(GTop.constants.size).to be > 5
  end

  it "maps methods onto classes, not just constants" do
    # A loader that registered the types but no methods would still satisfy a
    # constant count, so this is the assertion that catches it.
    klass = GTop.constants
      .map {|name| GTop.const_get(name) }
      .grep(Class)
      .find {|c| (c.instance_methods - Object.instance_methods).any? }

    expect(klass).not.to be_nil
  end

  it "loads the typelib's records as classes" do
    # Deliberately NOT asserting GLib::Object descent, which the other gems in
    # this family do assert. libgtop is introspected as plain C records --
    # glibtop_mountentry, glibtop_proc_map and friends -- and registers no
    # GObject types at all, so a GObject assertion here would be asserting
    # something untrue of the library rather than checking the loader.
    structs = GTop.constants
      .map {|name| GTop.const_get(name) }
      .grep(Class)

    expect(structs).not.to be(:empty?)
  end
end

# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module GTop
  # Defines everything in the GTop namespace from `GTop-2.0.typelib`.
  #
  # Modelled on ruby-gnome's own loaders -- see
  # gtksourceview5/lib/gtksourceview5/loader.rb for one that has to call the
  # library's init function before anything works, and
  # libsecret/lib/libsecret/loader.rb for one that does not.
  #
  # The version string is the typelib's, which is not always the library's
  # release number and is not guessable: this one is "2.0", read off
  # `GTop-2.0.typelib` rather than inferred.
  class Loader < GObjectIntrospection::Loader
    def load
      self.version = "2.0"
      super("GTop")
    end

    private

    # Every function in this namespace takes its result struct as the first
    # argument -- `glibtop_get_proc_uid(glibtop_proc_uid *buf, pid_t pid)` --
    # so without the struct classes the whole API is uncallable from Ruby.
    #
    # libgtop names those records `glibtop_proc_uid`, `glibtop_mountentry` and
    # so on, all lowercase. The loader derives a class name from the record
    # name and const_sets it, which for a lowercase name warns
    #   rb_define_const: invalid name 'glibtop_proc_uid' for constant
    # and defines nothing. The result was a namespace with 372 integer
    # constants, 36 module functions and not one class, discovered when
    # console-rb tried to read process statistics with it.
    #
    # So the name is made Ruby-shaped: the `glibtop_` prefix goes, and the rest
    # is CamelCased. `glibtop_proc_uid` becomes {GTop::ProcUid}, which is also
    # what a reader of the C API would guess. That silences the warnings and
    # gives 42 record classes with readable fields.
    #
    # It does NOT make the functions callable, and nothing in this gem can.
    # GObjectIntrospection resolves an argument's Ruby class from the raw GI
    # name, in RegisteredTypeInfo#resolve_class:
    #
    #     mod.const_defined?(name)   # name == "glibtop_proc_uid"
    #
    # and `const_defined?` raises `NameError: wrong constant name` for a
    # lowercase name whatever this gem calls the class. So
    # `GTop.glibtop_get_proc_uid(GTop::ProcUid.new, pid)` constructs its
    # argument and then dies resolving the argument's type. See the README.
    def rubyish_class_name(info)
      name = info.name
      return super if /\A[A-Z]/.match?(name)

      rest = name.sub(/\Aglibtop_?/, "")
      return "Glibtop" if rest.empty?

      rest.split("_").map(&:capitalize).join
    end

    # A Ruby constant has to begin with an uppercase letter, and this typelib
    # has names that do not. GTop-2.0 declares lowercase struct names such as `glibtop_mountentry`.
    # The default loader calls const_set regardless, which raises NameError
    # (or warns, for a lowercase name) and aborts the load partway through.
    #
    # ruby-gnome's own loaders override this hook for the same reason -- see
    # vte4 and webkit-gtk, which redirect `*_VERSION` constants into a Version
    # module. Here the values are kept in a hash rather than dropped, so
    # nothing in the typelib becomes unreachable.
    def load_constant_info(info)
      if /\A[A-Z]/.match?(info.name)
        super
      else
        GTop::UNNAMEABLE_CONSTANTS[info.name] = info.value
      end
    end

    def post_load(repository, namespace)
      require_libraries
    end

    def require_libraries
      # Nothing yet. Hand-written Ruby that improves on what the typelib gives
      # -- an each that yields, a to_s, a keyword-argument constructor -- goes
      # in files required from here, which is the convention ruby-gnome uses
      # for exactly that purpose.
    end
  end
end

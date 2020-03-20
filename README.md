[![Build Status](https://secure.travis-ci.org/robn/Prometheus-Tiny-Shared.png)](http://travis-ci.org/robn/Prometheus-Tiny-Shared)

# NAME

Prometheus::Tiny::Shared - A tiny Prometheus client with a shared database behind it

# SYNOPSIS

    use Prometheus::Tiny::Shared;

    my $prom = Prometheus::Tiny::Shared->new;

# DESCRIPTION

`Prometheus::Tiny::Shared` is a wrapper around [Prometheus::Tiny](https://metacpan.org/pod/Prometheus%3A%3ATiny) that instead of storing metrics data in a hashtable, stores them in a shared datastore (provided by [Hash::SharedMem](https://metacpan.org/pod/Hash%3A%3ASharedMem), though this may change in the future). This lets you keep a single set of metrics in a multithreaded app.

`Prometheus::Tiny::Shared` should be a drop-in replacement for `Prometheus::Tiny`. Any differences in behaviour is a bug, and should be reported.

# CONSTRUCTOR

## new

    my $prom = Prometheus::Tiny::Shared->new(filename => ...);

`filename`, if provided, will name an on-disk location to store the backing store. If not supplied, a temporary location will be created and destroyed when your program ends, so suitable for testing purposes. For best performance, this should be stored on some kind of memory-backed filesystem (eg Linux `tmpfs`). The store is not intended to be a persistant, durable store (Prometheus will handle metrics resetting to zero correctly), so you don't need to worry about backing it up or any other maintenance.

`init_file`, if set to true, will overwrite any existing data file with the given name. If you do this while you already have existing `Prometheus::Tiny::Shared` objects using the old file, strange things will probably happen. Don't do that.

The `cache_args` argument will cause the constructor to croak. Code using this arg in previous versions of Prometheus::Tiny::Shared no longer work, and needs to be updated to use the `filename` argument instead.

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/robn/Prometheus-Tiny-Shared/issues](https://github.com/robn/Prometheus-Tiny-Shared/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/robn/Prometheus-Tiny-Shared](https://github.com/robn/Prometheus-Tiny-Shared)

    git clone https://github.com/robn/Prometheus-Tiny-Shared.git

# AUTHORS

- Rob N ★ <robn@robn.io>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

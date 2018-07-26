[![Build Status](https://secure.travis-ci.org/robn/Prometheus-Tiny-Shared.png)](http://travis-ci.org/robn/Prometheus-Tiny-Shared)

# NAME

Prometheus::Tiny - A tiny Prometheus client backed by a shared memory region

# SYNOPSIS

    use Prometheus::Tiny::Shared;

    my $prom = Prometheus::Tiny::Shared->new;

# DESCRIPTION

`Prometheus::Tiny::Shared` is a wrapper around [Prometheus::Tiny](https://metacpan.org/pod/Prometheus::Tiny) that instead of storing metrics data in a hashtable, stores them in a shared memory region (provided by [Cache::FastMmap](https://metacpan.org/pod/Cache::FastMmap)). This lets you keep a single set of metrics in a multithreaded app.

`Prometheus::Tiny::Shared` should be a drop-in replacement for `Prometheus::Tiny`. Any differences in behaviour is a bug, and should be reported.

# CONSTRUCTOR

## new

    my $prom = Prometheus::Tiny::Shared->new(cache_args => { ... })

`cache_args` will be passed on to the `Cache::FastMmap` constructor. If not provided, `Cache::FastMmap`'s defaults will be used, but that's probably not what you want. At the very least you should read the discussion of `share_file` and `init_file` in [Cache::FastMmap](https://metacpan.org/pod/Cache::FastMmap).

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

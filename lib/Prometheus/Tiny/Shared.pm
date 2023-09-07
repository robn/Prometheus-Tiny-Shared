package Prometheus::Tiny::Shared;

# ABSTRACT: A tiny Prometheus client with a shared database behind it

use warnings;
use strict;

use Prometheus::Tiny 0.011;
use parent 'Prometheus::Tiny';

use Hash::SharedMem qw(shash_open shash_get shash_set shash_cset shash_keys_array shash_group_get_hash);
use JSON::XS qw(encode_json decode_json);
use File::Temp qw(tempdir);
use File::Path qw(rmtree);
use Carp qw(croak carp);
use Scalar::Util qw(looks_like_number);

sub new {
  my ($class, %args) = @_;

  if (exists $args{cache_args}) {
    croak <<EOF;
The 'cache_args' argument to Prometheus::Tiny::Shared::new has been removed. 
Read the docs for more info, and switch to the 'filename' argument.
EOF
  }

  my $filename = delete $args{filename};
  my $init_file = delete $args{init_file} || 0;

  my $self = $class->SUPER::new(%args);

  if ($filename) {
    rmtree($filename) if $init_file;
  }
  else {
    $filename = tempdir('pts-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
  }

  $self->{_shash} = shash_open($filename, 'rwc');

  return $self;
}

sub set {
  my ($self, $name, $value, $labels, $timestamp) = @_;

  unless (looks_like_number $value) {
    carp "setting '$name' to non-numeric value, using 0 instead";
    $value = 0;
  }

  my $key = join('-', 'k', $name, $self->_format_labels($labels));
  shash_set($self->{_shash}, $key, encode_json([$value, $timestamp]));

  return;
}

sub add {
  my ($self, $name, $diff, $labels) = @_;

  unless (looks_like_number $diff) {
    carp "adjusting '$name' by non-numeric value, adding 0 instead";
    $diff = 0;
  }

  my $key = join('-', 'k', $name, $self->_format_labels($labels));

  my ($ov, $nv);

  do {
    $ov = shash_get($self->{_shash}, $key);
    if ($ov) {
      my $ar = decode_json($ov);
      $ar->[0] += $diff;
      $nv = encode_json($ar);
    }
    else {
      $nv = encode_json([$diff]);
    }
  } until shash_cset($self->{_shash}, $key, $ov, $nv);

  return;
}

sub clear {
  my ($self, $name) = @_;

  for my $key (grep { substr($_, 0, 1) eq 'k' } @{shash_keys_array($self->{_shash})}) {
    shash_set($self->{_shash}, $key, undef);
  }

  return;
}

sub declare {
  my ($self, $name, %meta) = @_;

  my $key = join('-', 'm', $name);
  my $value = encode_json(\%meta);

  return if shash_cset($self->{_shash}, $key, undef, $value);

  my $old = decode_json(shash_get($self->{_shash}, $key));

  if (
    ((exists $old->{type} ^ exists $meta{type}) ||
      (exists $old->{type} && $old->{type} ne $meta{type})) ||
    ((exists $old->{help} ^ exists $meta{help}) ||
      (exists $old->{help} && $old->{help} ne $meta{help})) ||
    ((exists $old->{enum} ^ exists $meta{enum}) ||
      (exists $old->{enum} && $old->{enum} ne $meta{enum})) ||
    ((exists $old->{buckets} ^ exists $meta{buckets}) ||
      (exists $old->{buckets} && (
      @{$old->{buckets}} ne @{$meta{buckets}} ||
      grep { $old->{buckets}[$_] != $meta{buckets}[$_] } (0 .. $#{$meta{buckets}})
      ))
    ) ||
    ((exists $old->{enum_values} ^ exists $meta{enum_values}) ||
      (exists $old->{enum_values} && (
      @{$old->{enum_values}} ne @{$meta{enum_values}} ||
      grep { $old->{enum_values}[$_] ne $meta{enum_values}[$_] } (0 .. $#{$meta{enum_values}})
      ))
    )
  ) {
    croak "redeclaration of '$name' with mismatched meta";
  }

  return;
}

sub histogram_observe {
  my $self = shift;
  my ($name) = @_;

  my $key = join('-', 'm', $name);

  $self->{meta}{$name} = decode_json(shash_get($self->{_shash}, $key) || '{}');

  return $self->SUPER::histogram_observe(@_);
}

sub enum_set {
  my $self = shift;
  my ($name) = @_;

  my $key = join('-', 'm', $name);

  $self->{meta}{$name} = decode_json(shash_get($self->{_shash}, $key) || '{}');

  return $self->SUPER::enum_set(@_);
}

sub format {
  my $self = shift;

  my (%metrics, %meta);

  my $hash = shash_group_get_hash($self->{_shash});
  while ( my ($k, $v) = each %$hash ) {
    my ($t, $name, $fmt) = split '-', $k, 3;
    if ($t eq 'k') {
      $metrics{$name}{$fmt} = decode_json($v);
    }
    else {
      $meta{$name} = decode_json($v);
    }
  }
  $self->{metrics} = \%metrics;
  $self->{meta} = \%meta;

  return $self->SUPER::format(@_);
}

1;

__END__

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Prometheus-Tiny-Shared.png)](http://travis-ci.org/robn/Prometheus-Tiny-Shared)

=head1 NAME

Prometheus::Tiny::Shared - A tiny Prometheus client with a shared database behind it

=head1 SYNOPSIS

    use Prometheus::Tiny::Shared;

    my $prom = Prometheus::Tiny::Shared->new;

=head1 DESCRIPTION

C<Prometheus::Tiny::Shared> is a wrapper around L<Prometheus::Tiny> that instead of storing metrics data in a hashtable, stores them in a shared datastore (provided by L<Hash::SharedMem>, though this may change in the future). This lets you keep a single set of metrics in a multithreaded app.

C<Prometheus::Tiny::Shared> should be a drop-in replacement for C<Prometheus::Tiny>. Any differences in behaviour is a bug, and should be reported.

=head1 CONSTRUCTOR

=head2 new

    my $prom = Prometheus::Tiny::Shared->new(filename => ...);

C<filename>, if provided, will name an on-disk location to store the backing store. If not supplied, a temporary location will be created and destroyed when your program ends, so suitable for testing purposes. For best performance, this should be stored on some kind of memory-backed filesystem (eg Linux C<tmpfs>). The store is not intended to be a persistant, durable store (Prometheus will handle metrics resetting to zero correctly), so you don't need to worry about backing it up or any other maintenance.

C<init_file>, if set to true, will overwrite any existing data file with the given name. If you do this while you already have existing C<Prometheus::Tiny::Shared> objects using the old file, strange things will probably happen. Don't do that.

The C<cache_args> argument will cause the constructor to croak. Code using this arg in previous versions of Prometheus::Tiny::Shared no longer work, and needs to be updated to use the C<filename> argument instead.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Prometheus-Tiny-Shared/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Prometheus-Tiny-Shared>

  git clone https://github.com/robn/Prometheus-Tiny-Shared.git

=head1 AUTHORS

=over 4

=item *

Rob N ★ <robn@despairlabs.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob Norris <robn@despairlabs.com>

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

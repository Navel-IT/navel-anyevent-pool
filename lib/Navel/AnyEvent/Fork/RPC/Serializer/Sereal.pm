# Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-anyevent-pool is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::AnyEvent::Fork::RPC::Serializer::Sereal 0.1;

use Navel::Base;

use constant {
    SERIALIZER => '
use Sereal;

(
    sub {
        Sereal::Encoder->new()->encode(\@_);
    },
    sub {
        @{Sereal::Decoder->new()->decode(shift)};
    }
);
'
};

#-> methods

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::AnyEvent::Fork::RPC::Serializer::Sereal

=head1 COPYRIGHT

Copyright (C) 2015 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-anyevent-pool is licensed under the Apache License, Version 2.0

=cut

# Copyright (C) 2015-2016 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-anyevent-pool is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::AnyEvent::Pool 0.1;

use Navel::Base;

use Navel::AnyEvent::Pool::Timer;

use Navel::Utils qw/
    isint
    croak
    blessed
/;

#-> methods

sub new {
    my ($class, %options) = @_;
    
    $options{maximum} //= 0;
    $options{maximum_simultaneous_jobs} //= 0;
    
    croak('maximum must be a positive integer') unless isint($options{maximum}) > 0;
    croak('maximum_simultaneous_jobs must be a positive integer') unless isint($options{maximum_simultaneous_jobs}) > 0;

    my $self = {
        logger => blessed($options{logger}) && $options{logger}->isa('Navel::Logger') ? $options{logger} : undef,
        maximum => $options{maximum},
        maximum_simultaneous_jobs => $options{maximum_simultaneous_jobs},
        jobs => {
            timers => {}
        },
        on_callbacks => {}
    };

    if (defined $self->{logger}) {
        $self->{on_callbacks}->{on_disabled} = sub {
            $self->{logger}->info(shift->full_name . ': disabled.');
        };

        $self->{on_callbacks}->{on_maximum_simultaneous_jobs} = sub {
            $self->{logger}->warning(shift->full_name . ': there are too many jobs running (maximum of ' . $self->{maximum_simultaneous_jobs} . ').');
        };

        $self->{on_callbacks}->{on_singleton_already_running} = sub {
            $self->{logger}->info(shift->full_name . ': already running.');
        };
    }

    bless $self, ref $class || $class;
}

sub attach_timer {
    my ($self, %options) = @_;

    my $timer = delete $options{timer};

    my $package = 'Navel::AnyEvent::Pool::Timer';

    if (blessed($timer) && $timer->isa($package)) {
        $options{name} = $timer->{name};

        $package = $timer;
    }

    croak('a name must be provided to add a timer') unless defined $options{name};

    croak('a timer named ' . $options{name} . ' already exists') if exists $self->{jobs}->{timers}->{$options{name}};
    croak('too many jobs already registered (maximum of ' . $self->{maximum} . ')') if $self->{maximum} && @{$self->jobs} >= $self->{maximum};

    $self->{jobs}->{timers}->{$options{name}} = $package->new(
        %{$self->{on_callbacks}},
        %options,
        (
            pool => $self
        )
    );
}

sub detach_timer {
    my ($self, $name) = @_;

    croak('a name must be provided to detach a timer') unless defined $name;

    my $timer = $self->{jobs}->{timers}->{$name};

    $timer->detach_pool if defined $timer;

    $timer;
}

sub timers {
    [
        grep {
            $_->isa('Navel::AnyEvent::Pool::Timer')
        } @{shift->jobs}
    ];
}

sub jobs {
    [
        map {
            values %{$_}
        } values %{shift->{jobs}}
    ];
}

sub jobs_running {
    [
        grep {
            $_->{running}
        } @{shift->jobs}
    ];
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::AnyEvent::Pool

=head1 COPYRIGHT

Copyright (C) 2015-2016 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-anyevent-pool is licensed under the Apache License, Version 2.0

=cut

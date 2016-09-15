# Copyright (C) 2015-2016 Yoann Le Garff, Nicolas Boquet and Yann Le Bras
# navel-anyevent-pool is licensed under the Apache License, Version 2.0

#-> BEGIN

#-> initialization

package Navel::AnyEvent::Pool::Timer 0.1;

use Navel::Base;

use AnyEvent;

use Navel::Utils qw/
    isint
    blessed
    croak
/;

#-> methods

sub random_delay {
    my ($class, $interval) = @_;

    substr rand(
        isint($interval) == 1 ? $interval : 0
    ), 0, 3;
}

sub new {
    my ($class, %options) = @_;

    my $name = delete $options{name};
    my $callback = delete $options{callback};

    my %temp = (
        pool => delete $options{pool},
        enabled => delete $options{enabled},
        singleton => delete $options{singleton} || 0,
        on_enable => delete $options{on_enable},
        on_disable => delete $options{on_disable},
        on_disabled => delete $options{on_disabled},
        on_maximum_simultaneous_jobs => delete $options{on_maximum_simultaneous_jobs},
        on_singleton_already_running => delete $options{on_singleton_already_running}
    );

    my $self;

    if (ref $class) {
        $self = $class;

        $self->detach_pool() if blessed($temp{pool}) && $temp{pool}->isa('Navel::AnyEvent::Pool');

        $self->{$_} //= $temp{$_} for keys %temp;
    } else {
        croak('callback must a CODE reference') unless ref $callback eq 'CODE';

        $self = bless {
            name => $name // croak('a name must be provided to add a timer'),
            pool => $temp{pool},
            enabled => $temp{enabled} // 1,
            singleton => $temp{singleton},
            running => 0,
            on_enable => $temp{on_enable},
            on_disable => $temp{on_disable},
            on_disabled => $temp{on_disabled},
            on_maximum_simultaneous_jobs => $temp{on_maximum_simultaneous_jobs},
            on_singleton_already_running => $temp{on_singleton_already_running},
        }, $class;

        my $wrapped_callback = sub {
            unless ($self->is_pooled() && $self->{pool}->{maximum_simultaneous_jobs} && @{$self->{pool}->jobs_running()} >= $self->{pool}->{maximum_simultaneous_jobs}) {
                $callback->($self);
            } else {
                $self->{on_maximum_simultaneous_jobs}->($self) if ref $self->{on_maximum_simultaneous_jobs} eq 'CODE';
            }
        };

        $self->{callback} = sub {
            if ($self->{enabled}) {
                if ($self->{singleton}) {
                    unless ($self->{running}) {
                        $wrapped_callback->();
                    } else {
                        $self->{on_singleton_already_running}->($self) if ref $self->{on_singleton_already_running} eq 'CODE';
                    }
                } else {
                    $wrapped_callback->();
                }
            } else {
                $self->{on_disabled}->($self) if ref $self->{on_disabled} eq 'CODE';
            }
        };
    }

    my $splay = delete $options{splay};

    unless (exists $options{after}) {
        $options{after} = $splay ? __PACKAGE__->random_delay($options{interval}) : 0;
    }

    $self->{anyevent_timer} = AnyEvent->timer(
        %options,
        (
            cb => $self->{callback}
        )
    );

    $self;
}

sub full_name {
    __PACKAGE__ . '.' . shift->{name};
}

sub detach_pool {
    my $self = shift;

    my $detached;

    if ($self->is_pooled()) {
        $detached = delete $self->{pool}->{jobs}->{timers}->{$self->{name}};

        undef $self->{pool};
    }

    $detached;
}

sub is_pooled {
    my $self = shift;

    blessed($self->{pool}) && $self->{pool}->isa('Navel::AnyEvent::Pool');
}

sub begin {
    my $self = shift;

    $self->{running} = 1;

    $self;
}

sub end {
    my $self = shift;

    $self->{running} = 0;

    $self;
}

sub exec {
    shift->{callback}->();
}

sub enable {
    my $self = shift;

    $self->{enabled} = 1;

    $self->{on_enable}->($self) if ref $self->{on_enable} eq 'CODE';

    $self;
}

sub disable {
    my $self = shift;

    $self->{enabled} = 0;

    $self->{on_disable}->($self) if ref $self->{on_enable} eq 'CODE';

    $self;
}

# sub AUTOLOAD {}

sub DESTROY {
    my $self = shift;

    $self->detach_pool();

    undef $self->{anyevent_timer};

    undef $self->{callback};

    $self;
}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::AnyEvent::Pool::Timer

=head1 COPYRIGHT

Copyright (C) 2015-2016 Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

navel-anyevent-pool is licensed under the Apache License, Version 2.0

=cut

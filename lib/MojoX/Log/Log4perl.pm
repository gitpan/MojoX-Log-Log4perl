package MojoX::Log::Log4perl;
use Log::Log4perl;

use warnings;
use strict;

our $VERSION = '0.02';

sub new {
	my ($class, $conf_file) = (@_);
	
	$conf_file ||= {
		'log4perl.rootLogger' => 'DEBUG, SCREEN',
		'log4perl.appender.SCREEN' => 'Log::Log4perl::Appender::Screen',
		'log4perl.appender.SCREEN.layout' => 'PatternLayout',
		'log4perl.appender.SCREEN.layout.ConversionPattern' => '[%d] [mojo] [%p] %m%n',
	};
	
	Log::Log4perl->init_once($conf_file);

	my $self = {};
	bless $self, $class;
	return $self;
}

# Hmm. Ah, a picture of my mommy.
sub trace { shift->_get_logger->trace(@_) }
sub debug { shift->_get_logger->debug(@_) }
sub info  { shift->_get_logger->info(@_)  }
sub warn  { shift->_get_logger->warn(@_)  }
sub error { shift->_get_logger->error(@_) }
sub fatal { shift->_get_logger->fatal(@_) }

sub logwarn    { shift->_get_logger->logwarn(@_)    }
sub logdie     { shift->_get_logger->logdie(@_)     }
sub error_warn { shift->_get_logger->error_warn(@_) }
sub error_die  { shift->_get_logger->error_die(@_)  }
sub logcarp    { shift->_get_logger->logcarp(@_)    }
sub logcluck   { shift->_get_logger->logcluck(@_)   }
sub logcroak   { shift->_get_logger->logcroak(@_)   }
sub logconfess { shift->_get_logger->logconfess(@_) }

sub log {
    my ($self, $level, @msgs) = @_;

	my $logger = $self->_get_logger();
    
    # Check
    $level = lc $level;
	if ($level =~ m/^(?:trace|debug|info|warn|error|fatal)$/o) {
		$logger->$level(@msgs);
	}
	
    return $self;
}

sub is_trace { shift->_get_logger->is_trace }
sub is_debug { shift->_get_logger->is_debug }
sub is_info  { shift->_get_logger->is_info  }
sub is_warn  { shift->_get_logger->is_warn  }
sub is_error { shift->_get_logger->is_error }
sub is_fatal { shift->_get_logger->is_fatal }

sub is_level {
	my ($self, $level) = (@_);
	
	# Shortcut
	return 0 unless $level;
	
	# Check
	if ($level =~ m/^(?:trace|debug|info|warn|error|fatal)$/o) {
		my $level = "is_$level";
		my $logger = $self->_get_logger;
		return $logger->$level;
	}
	else {
		return 0;
	}
}

sub level {
	my ($self, $level) = (@_);
	my $logger = $self->_get_logger;

    require Log::Log4perl::Level;
    if ($level) {
    	return $logger->level( Log::Log4perl::Level::to_priority(uc $level) );
    }
    else {
		return Log::Log4perl::Level::to_level( $logger->level() );
    }
}

sub _get_logger {
    # get our caller
    my ($pkg, $line) = (caller())[0, 2];
    ($pkg, $line) = (caller(1))[0, 2] if $pkg eq ref shift;

    # get correct logger for our caller
    my $logger = Log::Log4perl->get_logger($pkg);
	return $logger;
}

__END__
=head1 NAME

MojoX::Log::Log4perl - Log::Log4perl logging for Mojo/Mojolicious

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

In lib/MyApp.pm:

  use MojoX::Log::Log4perl;

  # just create a custom logger object for Mojo/Mojolicious to use
  # (this is usually done inside the "startup" sub on Mojolicious).
  # If we dont supply any arguments to new, it will work almost
  # like the default Mojo logger.
  
  $self->log( MojoX::Log::Log4perl->new() );

  # But the real power of Log4perl lies in the configuration, so
  # lets try that. example.conf is included in the distribution.
  
  $self->log( MojoX::Log::Log4perl->new('example.conf') );

And later, inside any Mojo/Mojolicious module...

  $c->app->log->debug("This is using log4perl!");


=head1 DESCRIPTION:

This module provides a Mojo::Log implementation that uses Log::Log4perl as the underlying log mechanism. It provides all the methods listed in Mojo::Log (and many more from Log4perl - see below), so, if you already use Mojo::Log in your application, there is no need to change a single line of code!

There will be a logger component set for the package that called it. For example, if you were in the MyApp::Main package, the following:

  package MyApp::Main;
  use base 'Mojolicious::Controller';
	
  sub default {
      my ( $self, $c ) = @_;
      my $logger = $c->app->log;
      
      $logger->debug("Woot!");
  }

Would send a message to the C<< Myapp.Main >> Log4perl component. This allows you to seamlessly use Log4perl with Mojo/Mojolicious applications, being able to setup everything from the configuration file. For example, in this case, we could have the following C<< log4perl.conf >> file:

  # setup default log level and appender
  log4perl.rootLogger = DEBUG, FOO
  log4perl.appender.FOO = Log::Log4perl::Appender::File
  log4perl.appender.FOO.layout

  # setup so MyApp::Main only logs fatal errors
  log4perl.logger.MyApp.Main = FATAL

See L<< Log::Log4perl >> and L<< Log::Log4perl::Config >> for more information on how to configure different logging mechanisms based on the component.


=head1 INSTANTIATION

=head2 new

=head2 new($config)

This builds a new MojoX::Log::Log4perl object. If you provide an argument to new(), it will be passed directly to Log::Log4perl::init.
    
What you usually do is pass a file name with your Log4perl configuration. But you can also pass a hash reference with keys and values set as Log4perl configuration elements (i.e. left side of '=' vs. right side).

If you don't give it any arguments, the following default configuration is set:

  log4perl.rootLogger = DEBUG, SCREEN
  log4perl.appender.SCREEN = Log::Log4perl::Appender::Screen
  log4perl.appender.SCREEN.layout' = PatternLayout
  log4perl.appender.SCREEN.layout.ConversionPattern = [%d] [mojo] [%p] %m%n


=head1 LOG LEVELS

  $logger->warn("something's wrong");

Below are all log levels from MojoX::Log::Log4perl, in descending priority:

=head2 C<fatal>

=head2 C<error>

=head2 C<warn>

=head2 C<info>

=head2 C<debug>

=head2 C<trace>

Just like C<< Log::Log4perl >>: "If your configured logging level is WARN, then messages logged with info(), debug(), and trace() will be suppressed. fatal(), error() and warn() will make their way through, because their priority is higher or equal than the configured setting."

=head2 C<log>

You can also use the C<< log() >> method just like in C<< Mojo::Log >>:

  $logger->log( info => 'I can haz cheezburger');

But nobody does that, really.

=head1 CHECKING LOG LEVELS

  if ($logger->is_debug) {
      # expensive debug here
  }

As usual, you can (and should) avoid doing expensive log calls by checking the current log level:

=head2 C<is_fatal>

=head2 C<is_error>

=head2 C<is_warn>

=head2 C<is_info>

=head2 C<is_debug>

=head2 C<is_trace>

=head2 C<is_level>

You can also use the C<< is_level() >> method just like in C<< Mojo::Log >>:

  $logger->is_level( 'warn' );

But nobody does that, really.

=head1 ADDITIONAL LOGGING METHODS

The following log4perl methods are also available for direct usage:

=head2 C<logwarn>

   $logger->logwarn($message);
   
This will behave just like:

   $logger->warn($message)
       && warn $message;

=head2 C<logdie>

   $logger->logdie($message);
   
This will behave just like:

   $logger->fatal($message)
       && die $message;

If you also wish to use the ERROR log level with C<< warn() >> and C<< die() >>, you can:

=head2 C<error_warn>

   $logger->error_warn($message);
   
This will behave just like:

   $logger->error($message)
       && warn $message;

=head2 C<error_die>

   $logger->error_die($message);
   
This will behave just like:

   $logger->error($message)
       && die $message;


Finally, there's the Carp functions that do just what the Carp functions do, but with logging:

=head2 C<logcarp>

    $logger->logcarp();        # warn w/ 1-level stack trace

=head2 C<logcluck>

    $logger->logcluck();       # warn w/ full stack trace

=head2 C<logcroak>

    $logger->logcroak();       # die w/ 1-level stack trace

=head2 C<logconfess>

    $logger->logconfess();     # die w/ full stack trace

=head1 ATTRIBUTES

The original C<handle> and C<path> attributes from C<< Mojo::Log >> are not implemented as they make little sense in a Log4perl environment. The only attribute available, therefore, is C<level>.

=head2 C<level>

  my $level = $logger->level();
  
This will return an UPPERCASED string with the current log level (C<'DEBUG'>, C<'INFO'>, ...). You can also use this to force a level of your choosing:

  $logger->level('warn');  # forces 'warn' level (case-insensitive)

But you really shouldn't do that at all, as it breaks log4perl's configuration structure. The whole point of Log4perl is letting you setup your logging from outside your code. So, once again: don't do this.


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojo-log-log4perl at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Log-Log4perl>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Log::Log4perl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Log-Log4perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Log-Log4perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Log-Log4perl>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Log-Log4perl/>

=back


=head1 ACKNOWLEDGEMENTS

This module was heavilly inspired by L<< Catalyst::Log::Log4perl >>. A lot of the documentation and specifications were taken almost verbatim from it.

Also, this is just a minor work. Credit is really due to Michael Schilli and Sebastian Riedel, creators and maintainers of L<< Log::Log4perl >> and L<< Mojo >>, respectively.


=head1 SEE ALSO

L<< Log::Log4perl >>, L<< Mojo::Log >>, L<< Mojo >>, L<< Mojolicious >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

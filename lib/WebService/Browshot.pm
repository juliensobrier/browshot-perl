package WebService::Browshot;

use 5.006006;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use URI::Encode qw(uri_encode);

our $VERSION = '1.6.0';

=head1 NAME

WebService::Browshot - Perl extension for Browshot (L<http://www.browshot.com/>), a web service to create website screenshots.

=head1 SYNOPSIS

  use WebService::Browshot;
  
  my $browshot = WebService::Browshot->new(key => 'my_key');
  my $screenshot = $browshot->screenshot_create(url => 'http://www.google.com/');
  [...]
  $browshot->screenshot_thumbnail_file(id => $screenshot->{id}, file => 'google.png');

=head1 DESCRIPTION

Browshot (L<http://www.browshot.com/>) is a web service to easily make screenshots of web pages in any screen size, as any device: iPhone, iPad, Android, Nook, PC, etc. Browshot has full Flash, JavaScript, CSS, & HTML5 support.

The latest API version is detailed at L<http://browshot.com/api/documentation>. WebService::Browshot follows the API documentation very closely: the function names are similar to the URLs used (screenshot/create becomes C<screenshot_create()>, instance/list becomes C<instance_list()>, etc.), the request arguments are exactly the same, etc.

The library version matches closely the API version it handles: WebService::Browshot 1.0.0 is the first release for the API 1.0, WebService::Browshot 1.1.1 is the second release for the API 1.1, etc.

WebService::Browshot can handle most the API updates within the same major version, e.g. WebService::Browshot 1.0.0 should be compatible with the API 1.1 or 1.2.

The source code is available on github at L<https://github.com/juliensobrier/browshot-perl>.


=head1 METHODS

=over 4

=head2 new()

  my $browshot = WebService::Browshot->new(key => 'my_key', base => 'http://api.browshot.com/api/v1/', debug => 1]);

Create a new WebService::Browshot object. You must pass your API key (go to you Dashboard to find your API key).

Arguments:

=over 4

=item key

Required.  API key.

=item base

 Optional. Base URL for all API requests. You should use the default base provided by the library. Be careful if you decide to use HTTP instead of HTTPS as your API key could be sniffed and your account could be used without your consent.

=item debug

Optional. Set to 1 to print debug output to the standard output. 0 (disabled) by default.

=back

=cut

sub new {
  	my ($self, %args) = @_;

	my $ua = LWP::UserAgent->new();
	$ua->timeout(90);
	$ua->env_proxy;
	$ua->max_redirect(32); # for the simple API only
	$ua->agent("WebService::Browshot $VERSION");

  	my $browshot = {	
		_key	=> $args{key}	|| '',
		_base	=> $args{base}	|| 'https://api.browshot.com/api/v1/',
		_debug	=> $args{debug}	|| 0,

		_retry	=> 2,
		last_error	=> '',

		_ua		=> $ua,
	};

  return bless($browshot, $self);
}


=head2 api_version()

Return the API version handled by the library. Note that this library can usually handle new arguments in requests without requiring an update.

=cut

sub api_version {
	my ($self, %args) = @_;

	if ($VERSION =~ /^(\d+\.\d+)\.\d/) {
		return $1;
	}

	return $VERSION;
}



=head2 simple()

   $browshot->simple(url => 'http://mobilito.net')

Retrieve a screenshot in one function.

Return an aray (status code, PNG). See L<http://browshot.com/api/documentation#simple> for the list of possible status codes.

Arguments:

See L<http://browshot.com/api/documentation#simple> for the full list of possible arguments.

=over 4

=item url

Required. URL of the website to create a screenshot of.

=back

=cut

sub simple {
	my ($self, %args) = @_;

	my $url	= $self->make_url(action => 'simple', parameters => { %args });
	my $res = $self->{_ua}->get($url);

# 	$self->info($res->message);
# 	$self->info($res->request->as_string);
# 	$self->info($res->as_string);
	
	return ($res->code, $res->decoded_content);
}

=head2 simple_file()

   $browshot->simple_file(url => 'http://mobilito.net', file => '/tmp/mobilito.png')

Retrieve a screenshot and save it localy in one function.

Return an aray (status code, file name). The file name is empty if the screenshot wasa not retrieved. See L<http://browshot.com/api/documentation#simple> for the list of possible status codes.

Arguments:

See L<http://browshot.com/api/documentation#simple> for the full list of possible arguments.

=over 4

=item url

Required. URL of the website to create a screenshot of.

=item file

Required. Local file name to write to.

=back

=cut

sub simple_file {
	my ($self, %args) 	= @_;
	my $file			= $args{file}	|| $self->error("Missing file in simple_file");

	my $url	= $self->make_url(action => 'simple', parameters => { %args });
	my $res = $self->{_ua}->get($url);

	my $content = $res->decoded_content;

	if ($content ne '') {
		open TARGET, "> $file" or $self->error("Cannot open $file for writing: $!");
		binmode TARGET;
		print TARGET $content;
		close TARGET;

		return ($res->code, $file);
	}
	else {
		$self->error("No thumbnail retrieved");
		return ($res->code, '');
	}
}

=head2 instance_list()

Return the list of instances as a hash reference. See L<http://browshot.com/api/documentation#instance_list> for the response format.

=cut

sub instance_list {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'instance/list');
}

=head2 instance_create()

Create a private instance. See L<http://browshot.com/api/documentation#instance_create> for the response format.

=cut

sub instance_create {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'instance/create', parameters => { %args });
}

=head2 instance_info()

   $browshot->instance_info(id => 2)

Return the details of an instance. See L<http://browshot.com/api/documentation#instance_info> for the response format.

Arguments:

=over 4

=item id

Required. Instance ID

=back

=cut

sub instance_info  {
	my ($self, %args) 	= @_;
	my $id				= $args{id}	|| $self->error("Missing id in instance_info");

	return $self->return_reply(action => 'instance/info', parameters => { id => $id });
}

=head2 browser_list()

Return the list of browsers as a hash reference. See L<http://browshot.com/api/documentation#browser_list> for the response format.

=cut

sub browser_list {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'browser/list');
}

=head2 browser_info()

   $browshot->browser_info(id => 2)

Return the details of a browser. See L<http://browshot.com/api/documentation#browser_info> for the response format.

Arguments:

=over 4

=item id

Required. Browser ID

=back

=cut

sub browser_info  {
	my ($self, %args) 	= @_;
	my $id				= $args{id}	|| $self->error("Missing id in browser_info");

	return $self->return_reply(action => 'browser/info', parameters => { id => $id });
}

=head2 browser_create()

Create a custom browser. See L<http://browshot.com/api/documentation#browser_create> for the response format.

=cut

sub browser_create {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'browser/create', parameters => { %args });
}

=head2 screenshot_create()

  $browshot->screenshot_create(url => 'http://wwww.google.com/', instance_id => 3, size => 'page')

Request a screenshot. See L<http://browshot.com/api/documentation#screenshot_create> for the response format.

Arguments:

See L<http://browshot.com/api/documentation#screenshot_create> for the full list of possible arguments.

=over 4

=item url

Required. URL of the website to create a screenshot of.

=item instance_id

Optional. Instance ID to use for the screenshot.

=item size

Optional. Screenshot size.

=back

=cut

sub screenshot_create {
	my ($self, %args) 	= @_;
# 	my $url				= $args{url}			|| $self->error("Missing url in screenshot_create");
# 	my $instance_id		= $args{instance_id};
# 	my $screen			= $args{screen};
# 	my $size			= $args{size}			|| "screen";
# 	my $cache			= $args{cache};
# 	my $priority		= $args{priority};

	$self->error("Missing url in screenshot_create") 	if (! defined($args{url}));
# 	$args{size} = "screen" 					if (! defined($args{size}));

	return $self->return_reply(action => 'screenshot/create', parameters => { %args });
}

=head2 screenshot_info()

  $browshot->screenshot_info(id => 568978)

Get information about a screenshot requested previously. See L<http://browshot.com/api/documentation#screenshot_info> for the response format.

Arguments:

=over 4

=item id

Required. Screenshot ID.

=back

=cut

sub screenshot_info {
	my ($self, %args) 	= @_;
	my $id				= $args{id}	|| $self->error("Missing id in screenshot_info");


	return $self->return_reply(action => 'screenshot/info', parameters => { id => $id });
}

=head2 screenshot_list()

  $browshot->screenshot_list(limit => 50)

Get details about screenshots requested. See L<http://browshot.com/api/documentation#screenshot_list> for the response format.

Arguments:

=over 4

=item limit

Optional. Maximum number of screenshots to retrieve.

=back

=cut

sub screenshot_list {
	my ($self, %args) 	= @_;

	return $self->return_reply(action => 'screenshot/list', parameters => { %args });
}

=head2 screenshot_thumbnail()

  $browshot->screenshot_thumbnail(url => 'https://ww.browshot.com/screenshot/image/52942?key=my_key', width => 500)

Retrieve the screenshot, or a thumbnail. See L<http://browshot.com/api/documentation#thumbnails> for the response format.

Return an empty string if the image could not be retrieved.

Arguments:

See L<http://browshot.com/api/documentation#thumbnails> for the full list of possible arguments.

=over 4

=item url

 Required. URL of the screenshot (screenshot_url value retrieved from C<screenshot_create()> or C<screenshot_info()>). You will get the full image if no other argument is specified.

=item width

Optional. Maximum width of the thumbnail.

=item height

Optional. Maximum height of the thumbnail.

=back

=cut
sub screenshot_thumbnail {
	my ($self, %args) 	= @_;
	my $url				= $args{url}	|| $self->error("Missing url in screenshot_thumbnail");
	my $width			= $args{width};
	my $height			= $args{height};
	my $zoom			= $args{zoom};
	my $ratio			= $args{ratio};


	$url .= '&width='  . uri_encode($width)  if (defined $width);
	$url .= '&height=' . uri_encode($height) if (defined $height);
	$url .= '&zoom='   . uri_encode($zoom)   if (defined $zoom);
	$url .= '&ratio='  . uri_encode($ratio)  if (defined $ratio);

	my $res = $self->{_ua}->get($url);
	if ($res->is_success) {
		return $res->decoded_content; # raw image file content
	}
	else {
		$self->error("Error in thumbnail request: " . $res->as_string);
		return '';
	}
}

=head2 screenshot_thumbnail_file()

  $browshot->screenshot_thumbnail_file(url => 'https://ww.browshot.com/screenshot/image/52942?key=my_key', height => 500, file => '/tmp/google.png')

Retrieve the screenshot, or a thumbnail, and save it to a file. See L<http://browshot.com/api/documentation#thumbnails> for the response format.

Return an empty string if the image could not be retrieved or not saved. Returns the file name if successful.

Arguments:

See L<http://browshot.com/api/documentation#thumbnails> for the full list of possible arguments.

=over 4

=item url

 Required. URL of the screenshot (screenshot_url value retrieved from C<screenshot_create()> or C<screenshot_info()>). You will get the full image if no other argument is specified.

=item file

Required. Local file name to write to.

=item width

Optional. Maximum width of the thumbnail.

=item height

Optional. Maximum height of the thumbnail.

=back

=cut
sub screenshot_thumbnail_file {
	my ($self, %args) 	= @_;
	my $file			= $args{file}	|| $self->error("Missing file in screenshot_thumbnail_file");

	my $content = $self->screenshot_thumbnail(%args);

	if ($content ne '') {
		open TARGET, "> $file" or $self->error("Cannot open $file for writing: $!");
		binmode TARGET;
		print TARGET $content;
		close TARGET;

		return $file;
	}
	else {
		$self->error("No thumbnail retrieved");
		return '';
	}
}

=head2 account_info()

Return information about the user account. See L<http://browshot.com/api/documentation#account_info> for the response format.

=cut

sub account_info {
	my ($self, %args) = @_;
	
	return $self->return_reply(action => 'account/info');
}


# Private methods

sub return_reply {
	my ($self, %args) 	= @_;
# 	my $action			= $args{action};
# 	my $parameters		= $args{parameters};

	my $url	= $self->make_url(%args);
	
	my $res;
	my $try = 0;

	do {
		$self->info("Try $try");
		eval {
			$res = $self->{_ua}->get($url);
		};
		$self->error($@) if ($@);
		$try++;
	}
	until($try < $self->{_retry} && defined $@);

	if ($res->is_success) {
		my $info;
		eval {
			$info = decode_json($res->decoded_content);
		};
		if ($@) {
			$self->error("Invalid server response: " . $@);
			return $self->generic_error($@);
		}

		return $info;
	}
	else {
		$self->error("Server sent back an error: " . $res->status_code);
		return $self->generic_error($res->as_string);
	}
}

sub make_url {
	my ($self, %args) 	= @_;
	my $action			= $args{action}		|| '';
	my $parameters		= $args{parameters}	|| { };

	my $url = $self->{_base} . "$action?key=" . uri_encode($self->{_key}, 1);

	foreach my $key (keys %$parameters) {
		$url .= '&' . uri_encode($key) . '=' . uri_encode($parameters->{$key}, 1) if (defined $parameters->{$key});
	}

	$self->info($url);
	return $url;
}

sub info {
	my ($self, $message) = @_;

	if ($self->{_debug}) {
		print $message, "\n";
	}

	return '';
}

sub error {
	my ($self, $message) = @_;

	$self->{last_error} = $message;

	if ($self->{_debug}) {
		print $message, "\n";
	}

	return '';
}

sub generic_error {
	my ($self, $message) = @_;


	return { error => 1, message => $message };
}

=head1 CHANGES

=over 4

=item 1.5.1

Use binmode to create valid PNG files on Windows.

=item 1.4.1

Fix URI encoding.

=item 1.4.0

Add C<simple> and C<simple_file> methods.

=item 1.3.1

Retry requests (up to 2 times) to browshot.com in case of error

=back

=head1 SEE ALSO

See L<http://browshot.com/api/documentation> for the API documentation.

Create a free account at L<http://browshot.com/login> to get your free API key.

Go to L<http://browshot.com/dashboard> to find your API key after you registered.

=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
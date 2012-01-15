# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-Browshot.t'

#########################

# use Data::Dumper;

use Test::More tests => 140;
use lib '../lib/';
BEGIN { use_ok( 'WebService::Browshot' ); }
require_ok( 'WebService::Browshot' );


my $browshot = WebService::Browshot->new(
	key		=> 'vPTtKKLBtPUNxVwwfEKlVvekuxHyTXyi', # test1
# 	base	=> 'http://127.0.0.1:3000/api/v1/',
# 	debug	=> 1,
);

is($browshot->api_version(), '1.4', "API version");

SKIP: {
	# Check access to https://browshot.com/
	my $ua = LWP::UserAgent->new();
	$ua->timeout(60);
	$ua->env_proxy;

	my $response = $ua->get('https://browshot.com/');
# 	print $response->as_string, "\n";

    skip "Unable to access https://browshot.com/", 138 if (! $response->is_success);

	my ($code, $png) = $browshot->simple(url => 'http://mobilito.net/', cache => 60 * 60 * 24 * 365); # cached for a year
	ok( $code == 200, 								"Screenshot should be succesful: $code");
	ok( length($png) > 0, 							"Screenshot should be succesful");

    my $instances = $browshot->instance_list();
	
	ok( exists $instances->{free}, 					"List of free instances available");
	ok( exists $instances->{shared}, 				"List of shared instances available");
	ok( exists $instances->{private}, 				"List of private instances available");

	ok( scalar(@{$instances->{free}}) > 0, 			"At least one free instance is available");
	ok( scalar(@{$instances->{shared}}) > 0, 		"At least one shared instance is available");
	ok( scalar(@{$instances->{private}}) == 0, 		"No private instance is available");

	my $free = $instances->{free}->[0];
	ok( exists $free->{id}, 						"Instance ID is present");
	ok( exists $free->{width}, 						"Instance width is present");
	ok( exists $free->{height}, 					"Instance height is present");
	ok( exists $free->{load}, 						"Instance load is present");
	ok( exists $free->{browser}, 					"Instance browser is present");
	ok( exists $free->{browser}->{id}, 				"Instance browser ID is present");
	ok( exists $free->{browser}->{name}, 			"Instance browser name is present");
	ok( exists $free->{browser}->{javascript}, 		"Instance browser javascript is present");
	ok( exists $free->{browser}->{flash}, 			"Instance browser flash is present");
	ok( exists $free->{browser}->{mobile}, 			"Instance browser mobile is present");
	ok( exists $free->{type}, 						"Instance type is present");
	ok( exists $free->{active}, 					"Instance active is present");
	ok( $free->{active} == 1, 						"Instance is active");
	ok( exists $free->{screenshot_cost}, 			"Instance screenshot_cost is present");
	ok( $free->{screenshot_cost} == 0, 				"Instance cost is 0");



	my $instance = $browshot->instance_info(id => $free->{id});
	ok( $free->{id} == $free->{id}, 										"Correct instance ID");
	ok( $free->{width} == $free->{width}, 									"Correct instance width");
	ok( $free->{height} == $free->{height}, 								"Correct instance height");
	ok( $free->{load} == $free->{load}, 									"Correct instance load");
	ok( $free->{browser}->{id} == $free->{browser}->{id}, 					"Correct instance browser ID");
	ok( $free->{browser}->{name} eq $free->{browser}->{name}, 				"Correct instance browser ID");
	ok( $free->{browser}->{javascript} == $free->{browser}->{javascript}, 	"Correct instance browser javascript");
	ok( $free->{browser}->{flash} == $free->{browser}->{flash}, 			"Correct instance browser javascript");
	ok( $free->{browser}->{mobile} == $free->{browser}->{mobile}, 			"Correct instance browser javascript");
	ok( $free->{type} eq $free->{type}, 									"Correct instance type");
	ok( $free->{active} == $free->{active}, 								"Correct instance active");
	ok( $free->{screenshot_cost} == $free->{screenshot_cost}, 				"Correct instance screenshot_cost");

	my $missing = $browshot->instance_info(id => -1);
	ok( exists $missing->{error}, 					"Instance was not found");
	ok( exists $missing->{status}, 					"Instance was not found");


	my $wrong = $browshot->instance_create(width => 3000);
	ok( exists $wrong->{error}, 					"Instance width too large");

	$wrong = $browshot->instance_create(height => 3000);
	ok( exists $wrong->{error}, 					"Instance height too large");

	$wrong = $browshot->instance_create(browser_id => -1);
	ok( exists $wrong->{error}, 					"Invalid browser_id");

	# Instance is not actually created for test account, so the reply may not match our parameters
	my $fake = $browshot->instance_create();
	ok( exists $fake->{id}, 						"Instance was created");
	ok( exists $fake->{width}, 						"Instance was created");
	ok( exists $fake->{active}, 					"Instance was created");
	ok( exists $fake->{browser}, 					"Instance was created");
	ok( exists $fake->{browser}->{id}, 				"Instance was created");


	my $browsers = $browshot->browser_list();
	ok( scalar( keys %{$browsers} ) > 0,			"Browsers are available");


	my $browser_id = 0;
	foreach my $key (keys %{$browsers}) {
		$browser_id = $key;
		last;
	}
	ok( $browser_id > 0, 							"Browser ID is correct");
	
	my $browser = $browsers->{$browser_id};
	ok( exists $browser->{name}, 					"Browser name exists");
	ok( exists $browser->{user_agent}, 				"Browser user_agent exists");
	ok( exists $browser->{appname}, 				"Browser appname exists");
	ok( exists $browser->{vendorsub}, 				"Browser vendorsub exists");
	ok( exists $browser->{appcodename}, 			"Browser appcodename exists");
	ok( exists $browser->{platform}, 				"Browser platform exists");
	ok( exists $browser->{vendor}, 					"Browser vendor exists");
	ok( exists $browser->{appversion}, 				"Browser appversion exists");
	ok( exists $browser->{javascript}, 				"Browser javascript exists");
	ok( exists $browser->{mobile}, 					"Browser mobile exists");
	ok( exists $browser->{flash}, 					"Browser flash exists");


	# browser is not actually created for test account, so the reply may not match our parameters
	my $new = $browshot->browser_create(mobile => 1, flash => 1, user_agent => 'test');
	ok( exists $new->{name}, 						"Browser name exists");
	ok( exists $new->{user_agent}, 					"Browser user_agent exists");
	ok( exists $new->{appname}, 					"Browser appname exists");
	ok( exists $new->{vendorsub}, 					"Browser vendorsub exists");
	ok( exists $new->{appcodename}, 				"Browser appcodename exists");
	ok( exists $new->{platform}, 					"Browser platform exists");
	ok( exists $new->{vendor}, 						"Browser vendor exists");
	ok( exists $new->{appversion}, 					"Browser appversion exists");
	ok( exists $new->{javascript}, 					"Browser javascript exists");
	ok( exists $new->{mobile}, 						"Browser mobile exists");
	ok( exists $new->{flash}, 						"Browser flash exists");



	# screenshot is not actually created for test account, so the reply may not match our parameters
	my $screenshot = $browshot->screenshot_create();
	ok( exists $screenshot->{error}, 				"Screenshot failed");

	$screenshot = $browshot->screenshot_create(url => '-');
	ok( exists $screenshot->{error}, 				"Screenshot failed");

	$screenshot = $browshot->screenshot_create(url => 'http://browshot.com/');
	ok( exists $screenshot->{id}, 					"Screenshot ID is present");
	ok( exists $screenshot->{status}, 				"Screenshot status is present");
	ok( exists $screenshot->{priority}, 			"Screenshot priority is present");
	
	SKIP: {
		skip "Screenshot is not finished", 16 if ($screenshot->{status} ne 'finished');

		ok( exists $screenshot->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot->{url}, 				"Screenshot url is present");
		ok( exists $screenshot->{size}, 			"Screenshot size is present");
		ok( exists $screenshot->{width}, 			"Screenshot width is present");
		ok( exists $screenshot->{height}, 			"Screenshot height is present");
		ok( exists $screenshot->{request_time}, 	"Screenshot request_time is present");
		ok( exists $screenshot->{started}, 			"Screenshot started is present");
		ok( exists $screenshot->{load}, 			"Screenshot load is present");
		ok( exists $screenshot->{content}, 			"Screenshot content is present");
		ok( exists $screenshot->{finished}, 		"Screenshot finished is present");
		ok( exists $screenshot->{instance_id}, 		"Screenshot instance_id is present");
		ok( exists $screenshot->{response_code}, 	"Screenshot response_code is present");
		ok( exists $screenshot->{final_url}, 		"Screenshot final_url is present");
		ok( exists $screenshot->{content_type}, 	"Screenshot content_type is present");
		ok( exists $screenshot->{scale}, 			"Screenshot scale is present");
		ok( exists $screenshot->{cost}, 			"Screenshot cost is present");
	}

	my $screenshot2 = $browshot->screenshot_info();
	ok( exists $screenshot2->{error}, 				"Screenshot is missing");

	$screenshot2 = $browshot->screenshot_info(id => $screenshot->{id});
	ok( exists $screenshot2->{id}, 					"Screenshot ID is present");
	ok( exists $screenshot2->{status}, 				"Screenshot status is present");
	ok( exists $screenshot2->{priority}, 			"Screenshot priority is present");

	SKIP: {
		skip "Screenshot is not finished", 16 if ($screenshot2->{status} ne 'finished');

		ok( exists $screenshot2->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot2->{url}, 			"Screenshot url is present");
		ok( exists $screenshot2->{size}, 			"Screenshot size is present");
		ok( exists $screenshot2->{width}, 			"Screenshot width is present");
		ok( exists $screenshot2->{height}, 			"Screenshot height is present");
		ok( exists $screenshot2->{request_time}, 	"Screenshot request_time is present");
		ok( exists $screenshot2->{started}, 		"Screenshot started is present");
		ok( exists $screenshot2->{load}, 			"Screenshot load is present");
		ok( exists $screenshot2->{content}, 		"Screenshot content is present");
		ok( exists $screenshot2->{finished}, 		"Screenshot finished is present");
		ok( exists $screenshot2->{instance_id}, 	"Screenshot instance_id is present");
		ok( exists $screenshot2->{response_code}, 	"Screenshot response_code is present");
		ok( exists $screenshot2->{final_url}, 		"Screenshot final_url is present");
		ok( exists $screenshot2->{content_type}, 	"Screenshot content_type is present");
		ok( exists $screenshot2->{scale}, 			"Screenshot scale is present");
		ok( exists $screenshot2->{cost}, 			"Screenshot cost is present");
	}

	my $screenshots;
	eval {
		$screenshots = $browshot->screenshot_list();
	};
	print $@, "\n" if ($@);
	ok( scalar (keys %$screenshots) > 0, 			"Screenshots are present");

	my $screenshot_id = 0;
	foreach my $key (keys %$screenshots) {
		$screenshot_id = $key;
		last;
	}
	ok( $screenshot_id > 0, 						"Screenshot ID is correct");
	
	$screenshot = '';
	eval {
		$screenshot = $screenshots->{$screenshot_id};
	};
# 	print $@, "\n" if ($@);
	
	ok( exists $screenshot->{id}, 					"Screenshot ID is present");
	ok( exists $screenshot->{status}, 				"Screenshot status is present");
	ok( exists $screenshot->{priority}, 			"Screenshot priority is present");
	ok( exists $screenshot->{screenshot_url}, 		"Screenshot screenshot_url is present");
	ok( exists $screenshot->{url}, 					"Screenshot url is present");
	ok( exists $screenshot->{size}, 				"Screenshot size is present");
	ok( exists $screenshot->{width}, 				"Screenshot width is present");
	ok( exists $screenshot->{height}, 				"Screenshot height is present");
	ok( exists $screenshot->{request_time}, 		"Screenshot request_time is present");
	ok( exists $screenshot->{started}, 				"Screenshot started is present");
	ok( exists $screenshot->{load}, 				"Screenshot load is present");
	ok( exists $screenshot->{content}, 				"Screenshot content is present");
	ok( exists $screenshot->{finished}, 			"Screenshot finished is present");
	ok( exists $screenshot->{instance_id}, 			"Screenshot instance_id is present");
	ok( exists $screenshot->{response_code}, 		"Screenshot response_code is present");
	ok( exists $screenshot->{final_url}, 			"Screenshot final_url is present");
	ok( exists $screenshot->{content_type}, 		"Screenshot content_type is present");
	ok( exists $screenshot->{scale}, 				"Screenshot scale is present");
	ok( exists $screenshot->{cost}, 				"Screenshot scale is present");

	# Thumbnail
	# TODO



	my $account = $browshot->account_info();
	ok( exists $account->{balance}, 				"Account balance is present");
	is( $account->{balance}, 0, 					"Balance is empty");
	ok( exists $account->{active}, 					"Account active is present");
	is( $account->{active}, 1, 						"Account is active");
	ok( exists $account->{instances}, 				"Account instances is present");



	# Error tests
	$browshot = WebService::Browshot->new(
		key		=> '', # test1
	# 	debug	=> 1,
	);

	$account = $browshot->account_info();
	ok( exists $account->{error}, 				"Missing key");
}

# done_testing(138);
#!/usr/bin/perl -w
use strict;
package Metrics::metric_unique_identifier;

use LWP::Simple;
use RDF::Trine;
use JSON::Parse 'parse_json';
use DateTime;
use CGI;
use lib '../';
use FAIRMetrics::TesterHelper;

require Exporter;
use vars ('@ISA', '@EXPORT');
@ISA = qw(Exporter);
@EXPORT = qw(execute_metric_test);


my %schemas = ('spec'  => ['string', "The URL, including GET string parameters, that will return a successful search for the subject resource"],
	       'subject' => ['string', "the GUID being tested"]);


my $helper = FAIRMetrics::TesterHelper->new(
				title => "FAIR Metrics - Metric Unique Identifier",
				description => "Metric to test if the resource uses a registered identifier scheme that guarantees global uniqueness.  The metric uses the FAIRSharing registry to check the response, so the schema used must be included in the registry.",
				tests_metric => 'https://purl.org/fair-metrics/FM_A1.1',
				applies_to_principle => "F1",
				organization => 'FAIR Metrics Authoring Group',
				org_url => 'http://fairmetrics.org',
				responsible_developer => "Mark D Wilkinson",
				email => 'markw@illuminae.com',
				developer_ORCiD => '0000-0001-6960-357X',
				host => 'linkeddata.systems',
				basePath => '/cgi-bin',
				path => '/fair_metrics/Metrics/metric_unique_identifier',
				response_description => 'The response is a binary (1/0), success or failure',
				schemas => \%schemas,
				fairsharing_key_location => '../fairsharing.key'
				);

my $cgi = CGI->new();
if (!$cgi->request_method() || $cgi->request_method() eq "GET") {
        print "Content-type: application/openapi+yaml;version=3.0\n\n";
        print $helper->getSwagger();
	
} else {
	return 1;  # this is returning 1 for the "require" statement in fair_metrics!!!!
}

sub execute_metric_test {
	my ($self, $body) = @_;

	my $json = parse_json($body);
	my $check = $json->{'spec'};
	my $IRI = $json->{'subject'};

        my $valid = get_valid_schemas($check, $IRI);
        
        my $value;
        if( $valid) {
                $value = "1";
                $helper->addComment("All OK!");
        } else {
                $value = "0";
                $helper->addComment("Failed to find the UUID in the output from  '$check'");
        }

	my $response = $helper->createEvaluationResponse($IRI, $value);

	print "Content-type: application/json\n\n";
	print $response;
	exit 1;
}


sub get_valid_schemas {

	use LWP::UserAgent;
	my $browser = LWP::UserAgent->new;
	my $url = 'https://fairsharing.org/api/standard/summary/?type=identifier%20schema';	
	my @ns_headers = (
  		'User-Agent' => 'Mozilla/4.76 [en] (Win98; U)', 
  		'Accept' => 'application/json',
  		'Api-Key' => 'cb892c4261a01b6842c4787ae6cba21a826b0bce');
	my $res = $browser->get($url, @ns_headers);

	unless ($res->is_success) {
		return [];
	} else {
		my @response;
		my $resp = $res->decoded_content;
		my $hash = parse_json ($resp);

		foreach my $result(@{$hash->{results}}) {
			 push @response, 'https://fairsharing.org/' . $result->{bsg_id};
			 push @response, $result->{doi};
		}
		# need to deal with "next page" one day!
		return \@response;
	}

}





1; #



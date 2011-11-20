use 5.006006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Browshot',
    VERSION_FROM      => 'lib/WebService/Browshot.pm', # finds $VERSION
    PREREQ_PM         => {
		URI::Encode				=> 0,
		JSON					=> 0,
		LWP::UserAgent			=> 0,
		LWP::Protocol::https	=> 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Browshot.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <julien@sobrier.net>') : ()),
);

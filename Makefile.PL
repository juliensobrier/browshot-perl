use 5.006006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WebService::Browshot',
    VERSION_FROM      => 'lib/WebService/Browshot.pm', # finds $VERSION
    PREREQ_PM         => {
		URI::Encode		=> 0,
		JSON			=> 0,
		LWP::UserAgent		=> 0,
		LWP::Protocol::https	=> 0,
		IO::Socket::SSL		=> 0,
	},
    META_MERGE => {
	'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/juliensobrier/browshot-perl.git',
				web => 'https://github.com/juliensobrier/browshot-perl',
			},
		},
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Browshot.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <julien@sobrier.net>') : ()),
);

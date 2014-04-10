#! perl -T
use Test::More;

use Log::Log4perl;

my $conf = q|
log4perl.rootLogger=TRACE, Chunk

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%X{chunk} %d %F{1} %L> %m %n

log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk
log4perl.appender.Chunk.layout=${layout_class}
log4perl.appender.Chunk.layout.ConversionPattern=${layout_pattern}
|;

Log::Log4perl::init(\$conf);

ok( my $ca =  Log::Log4perl->appender_by_name('Chunk') , "Ok got Chunk appender");

my $LOGGER = Log::Log4perl->get_logger();

ok( $ca->store() , "Ok got store");

is( $ca->state() , 'OFFCHUNK');

$LOGGER->info("Something outside any context");

Log::Log4perl::MDC->put('chunk', '12345');

is( $ca->state() , 'OFFCHUNK');

$LOGGER->trace("Some trace inside the chunk");
is( $ca->state() , 'ENTERCHUNK');

$LOGGER->debug("Some debug inside the chunk");
is( $ca->state() , 'INCHUNK');

$LOGGER->info("Some info inside the chunk");
is( $ca->state() , 'INCHUNK');

Log::Log4perl::MDC->put('chunk', undef);

$LOGGER->info("Outside context again");
is( $ca->state() , 'LEAVECHUNK');

Log::Log4perl::MDC->put('chunk', '0001');
$LOGGER->info("Inside another chunk");
is( $ca->state() , 'ENTERCHUNK');

$LOGGER->info("Inside another chunk again");
is( $ca->state() , 'INCHUNK');


Log::Log4perl::MDC->put('chunk' , '0002' );
$LOGGER->info("Inside a brand new chunk");
is( $ca->state() , 'NEWCHUNK');

$LOGGER->info("Inside a brand new chunk again");
is( $ca->state() , 'INCHUNK');
Log::Log4perl::MDC->put('chunk' , undef );
$LOGGER->info("Left chunk context");
is( $ca->state() , 'LEAVECHUNK');

$LOGGER->info("Left chunk context again");
is( $ca->state() , 'OFFCHUNK');

ok(1);

done_testing();

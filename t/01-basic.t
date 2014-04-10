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

my $LOGGER = Log::Log4perl->get_logger();

$LOGGER->info("Something outside any context");

Log::Log4perl::MDC->put('chunk', '12345');

$LOGGER->trace("Some trace inside the chunk");
$LOGGER->debug("Some debug inside the chunk");
$LOGGER->info("Some info inside the chunk");

Log::Log4perl::MDC->put('chunk', undef);

$LOGGER->info("Outside context again");

ok(1);

done_testing();

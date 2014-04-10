#! perl -T
use Test::More;

use Log::Log4perl;

my $conf = q|
log4perl.rootLogger=TRACE, Chunk

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk
log4perl.appender.Chunk.layout=${layout_class}
log4perl.appender.Chunk.layout.ConversionPattern=${layout_pattern}
|;

Log::Log4perl::init(\$conf);

my $LOGGER = Log::Log4perl->get_logger();

$LOGGER->info("Something");

ok(1);

done_testing();

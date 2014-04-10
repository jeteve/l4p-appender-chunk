#! perl -T
use Test::More;

use Log::Log4perl;

my $conf = q|
log4perl.rootLogger=TRACE, Chunk

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%m%n

log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk
log4perl.appender.Chunk.store_class=S3
log4perl.appender.Chunk.store_args.bucket_name=MyShinyBucket
log4perl.appender.Chunk.store_args.aws_access_key_id=Boudin
log4perl.appender.Chunk.store_args.aws_secret_access_key=Blanc
log4perl.appender.Chunk.layout=${layout_class}
log4perl.appender.Chunk.layout.ConversionPattern=${layout_pattern}
|;

Log::Log4perl::init(\$conf);

ok( my $ca =  Log::Log4perl->appender_by_name('Chunk') , "Ok got Chunk appender");
ok( my $store = $ca->store() , "Ok got store for the logger");
ok( $store->s3_client() , "Ok got s3 client");

done_testing();

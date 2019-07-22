#!/usr/bin/env perl
# by William Hofferbert
# attempt to fix wav files that were written too large to be fully playable
use 5.010;				# for say
use strict;				# good form
use warnings;				# know when stuff is wrong
use autodie;				# probably a good idea
use Data::Dumper;			# debug
use File::Basename;			# know where the script lives
use Getopt::Long;			# handle arguments

#
# Default Variables
#

my $prog = basename($0);		# script name
my ($infile, $outfile);			# in/out files

my @header_try_bytes = (44, 56);	# array of header bytes to try

my %header_info;			# hash to hold all header info

my $debug_on;				# extra output

#
# Functions
#

sub usage {
  my $header_bytes_str = join(", ", @header_try_bytes);
  my $usage = <<"  END_USAGE";

  This program can fix a wav file that was recorded too long,
  by analyzing the headers and data, then writing multiple
  subsequent wav files, which will contain the music data, and
  should all be fully playable.

    Basic Usage: $prog [path/to/infile.wav] [outfile_name]

  ptions:

    -header-bytes [INT]
      Provide another number of wav header bytes to test.
      Default byte numbers to try: ($header_bytes_str)

    -help
      Print this help.

    -debug
      Print extra debug info.

  Examples:

    $prog ./path/to/infile.wav outfile
      Produce segments, outfile1.wav, outfile2.wav, ..., outfile(N).wav,
      until there is no more valid audio data left to split.
 
  END_USAGE

  say "$usage";
  exit(0);
}

sub check_required_args {
  $infile = $ARGV[0];
  $outfile = $ARGV[1];
  if (!defined $infile || !defined $outfile) {
    &err("$prog requires infile and outfile!\nSee $prog -help for more details.");
  }
}

sub handle_args {
  if ( Getopt::Long::GetOptions(
    'header-bytes=i' => sub{push @header_try_bytes, $_[1]},
    'debug' => \$debug_on,
    'h|help' => \&usage,
     ) )   {
    &check_required_args;
  }
}

sub err {
  my $msg=shift;
  say STDERR $msg;
  exit 2;
}

sub warn {
  my $msg=shift;
  say STDERR $msg;
}

sub get_header_info {
  # for all the header bytes we can try,
  # iterate over the headers, testing for expected data
  for my $header_bytes (@header_try_bytes) {
    say "Testing header size $header_bytes" if $debug_on;
    open my $FH, "<:raw", $infile;
    my $data;
    read($FH, $data, $header_bytes);
    my $check = substr($data, -8, 4);
    if ($check eq "data") {
      say "Matched header size $header_bytes" if $debug_on;
      $header_info{top} = "RIFF";
      $header_info{totalsize} = substr($data, 4, 4);
      $header_info{mid} = substr($data, 8, $header_bytes - 12);
      $header_info{datasize} = substr($data, -4);
      $header_info{bytes} = $header_bytes;
    }
    close $FH;
  }
  if (! exists $header_info{top}) {
    &err("Could not determine header info!");
  }
}

sub ret_header_chunk {
  my $ret;
  $ret.=$header_info{top};
  $ret.=$header_info{totalsize};
  $ret.=$header_info{mid};
  $ret.=$header_info{datasize};
  return $ret;
}

sub write_outfile_in_chunks {
  #my $max_wav_size = 1667718192;		# initial value used...
  my $max_wav_size = 2147483640;		# needs to be less than 2147483647 and divisible by 8

  my $header_bytes = $header_info{bytes};
  my $max_wav_data_chunk = $max_wav_size - $header_bytes;

  my $infile_size = (stat($infile))[7];
  
  # starting position for seeks
  my $position = $header_bytes;

  my $oufile_increment = 1;

  while ($position lt $infile_size) {
    # if we are near the end of the file, fix header sizes
    if ($position + $max_wav_data_chunk gt $infile_size) {
      say "Near end of file" if $debug_on;
      # adjust header file sizes to match remaining data
      my $remaining_data = ($infile_size - $position);
      $header_info{totalsize} = pack('l', $remaining_data + $header_info{bytes} - 8);
      $header_info{datasize} = pack('l', $remaining_data);
    } else {
      $header_info{totalsize} = pack('l', $max_wav_data_chunk + $header_info{bytes});
      $header_info{datasize} = pack('l', $max_wav_data_chunk);
    }

    my $outfile_name = $outfile . $oufile_increment . ".wav";
    say "Writing to output file $outfile_name";

    # write headers and next block
    open my $IFH, "<", $infile;
    open my $OFH, ">", $outfile_name;
    print $OFH &ret_header_chunk;

    seek($IFH,$position,0);
    my $data;
    read($IFH, $data, $max_wav_data_chunk);
    print $OFH $data;

    close $IFH;
    close $OFH;

    $oufile_increment++;
    $position+=$max_wav_data_chunk;
  }
}

sub main {
  &handle_args;			# deal with arguments
  &get_header_info;		# get wav header structure
  &write_outfile_in_chunks;	# write new files
}

&main;


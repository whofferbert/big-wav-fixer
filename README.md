# big-wav-fixer
Fix wav files that were written too big

## Purpose
This script was written to resolve issues with .wav format files that were written when recording a very long session. Due to the way wav headers need to be written, the files can only grow so large, until you can't reach the data at the end.

Having accidentally recorded for 4.5 hours at 96khz, I wound up with a wav file that was 6gb, and every program I tried to use could only get to the first 1h:12 of the file. This is due to a limitation in the header structure of WAV files; they cannot address files more than 2147483647 bytes long, and the audio data must take up less space than that.

This script can take a big, not-fully-addressable wav file, and rewrite it into smaller files that are fully addressable. It does so by determining where the header info ends in the current, broken file, and then rewriting the audio data into chunks which can be addressed properly by the wav headers.

## help text

```bash

  This program can fix a wav file that was recorded too long,
  by analyzing the headers and data, then writing multiple
  subsequent wav files, which will contain the music data, and
  should all be fully playable.

    Basic Usage: big_broken_wav_fixer.pl [path/to/infile.wav] [outfile_name]

  ptions:

    -header-bytes [INT]
      Provide another number of wav header bytes to test. 
      Defaults number of bytes to test: (44, 56)

    -help
      Print this help.

    -debug
      Print extra debug info.

  Examples:

    big_broken_wav_fixer.pl ./path/to/infile.wav outfile
      Produce segments, outfile1.wav, outfile2.wav, ..., outfile(N).wav,
      until there is no more valid audio data left to split.

```

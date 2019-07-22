# big-wav-fixer
Fix wav files that were written too big

## Purpose
This script was written to resolve issues with .wav format files that were written when recording a very long session. Due to the way the headers need to be written, the files can only grow so large, until you can't reach the data at the end.

Having accidentally recorded for 4.5 hours, and winding up with a wav file that was 6gb, I could only get to the first 1h:12 of the file.

This script can take a big, not-fully-addressable wav file, and rewrite it into smaller chunks that are fully addressable.

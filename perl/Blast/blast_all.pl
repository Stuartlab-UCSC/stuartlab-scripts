#!/usr/bin/perl

use strict;


#blast_all.pl -BLAST (blastpgp) all the seqs. in the input file (FASTA format) 
#           against a database
#
#Writes output to a directory, expects input file in STDIN.
#
#---------------------------
# Josh Stuart, adapted from Jim Lund's script
# jstuart@stanford.edu
#
# Postal address: Department of Developmental Biology, B365
#                279 Campus Dr.
#                Stanford, CA 94305
#
# Web site: http://www.smi.stanford.edu/people/stuart
#---------------------------
#
# Written: 2-20-00
# Updated: 3-01-02

my $db='';
my $outdir = '';
my $arg;
my $query_file='';

if($#ARGV==-1)
{
  print STDOUT <DATA>;
  exit(0);
}

if($#ARGV<2)
{
  print STDERR "Not enough input arguments specified, use --help for help.\n";
  exit(1);
}

while(@ARGV)
{
  $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print <DATA>;
    exit(0);
  }
  elsif(-d $arg and length($outdir)<1)
  {
    $outdir = $arg;
  }
  elsif(length($db)<1)
  {
    $db = $arg;
  }
  elsif(-f $arg and length($query_file)<1)
  {
    $query_file = $arg;
  }
  else
  {
    print <DATA>;
    exit(1);
  }
}

# blast_all [OPTIONS] OUTDIR DB QUERY
if(length($outdir)<1)
{
  die("No output directory supplied.\n");
}
if(length($db)<1)
{
  die("No output database path supplied.\n");
}
if(length($query_file)<1)
{
  die("No output query file supplied.\n");
}

if(not(open(QUERY,$query_file)))
{
  print STDERR "Could not open query file '$query_file': $!.\n";
  exit(2);
}

#Read through the file of FASTA formatted sequences to be searched.
#Send off a search whenever the end of a seq. is detected.
my $seq;
my $name;
while(<QUERY>)
{
  #If we hit a new seq. and $seq exists, do the BLAST.
  if (($_ =~ /^>(\S+)/) && $seq) 
  {
    print STDERR "BLASTING seq='$seq' name='$name'\n";
    &DO_BLAST($seq,$name,$outdir);
    $seq='';
  }

  #Pull the file name from the FASTA descriptor.
  if ($_ =~ /^>/)
  {
    ($name)= $_=~ />(.+)$/;
    $name=~s/\s.*$//;
  }
  $seq.=$_;

}

#And call it once more for the final seq.
&DO_BLAST($seq,$name,$outdir);


sub DO_BLAST
{
  my ($seq,$name,$outdir)=@_;

  #
  #Write the temp file.
  #
  my $tmp_fasta='/tmp/tmp_' . time;
  open(FILE,'>'.$tmp_fasta) or die "Can't open file '$tmp_fasta': $!\n";
  print FILE $seq;
  close FILE or warn "Can't close file $tmp_fasta: $!\n";

  my $outfile="$outdir/$name.blastp";

  if (system "blastall -p blastp -d $db -o $outfile < $tmp_fasta") {
      print STDERR "Error with $name!: $!\n";
      }

  `gzip $outfile`;

  #
  #Delete temp. file.
  #
  unlink $tmp_fasta;
}

__DATA__

blast_all [OPTIONS] OUTDIR DB QUERY

BLAST (blastpgp) all the sequences in QUERY file(s) (FASTA formatted sequences)
against a database.

OUTDIR - directory where results should be written.
DB - the path to the formatdb formatted database files (include the entire
     filename path except the last extensions generated by formatdb)
QUERY - FASTA sequences to be queried against the database.

OPTIONS are:

The program takes the first word of the FASTA descriptor as the base name
of the BLAST output file.

A .ncbirc file must exist, usually in the home directory of the user
running this program.

Example .ncbirc file:
------------------
[NCBI] 
Data=/usr/local/ncbi/blast/data

[BLAST]
BLASTDB=/data2/jiml/blast
------------------

Example: 
blast_all ./blast_output < wormpep68


Written by Jim Lund in the lab of Stuart Kim, Stanford University.
jiml@stanford.edu, http://worm-chip.stanford.edu

Version: 1.000
Last updated: 11-01-01

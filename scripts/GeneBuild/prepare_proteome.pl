#!/usr/local/bin/perl -w
use strict;

=head1 NAME

  prepare_proteome.pl

=head1 SYNOPSIS
 
  prepare_proteome.pl

=head1 DESCRIPTION

  prepare_proteome.pl prepares a fasta file of protein sequences from swissprot and refseq 
  input files (also in fasta format). This file is needed for pmatch comparisons and its 
  creation is the first part of the GeneBuild.

  The file has a description line consisting solely of the accession number after the leading >
  All U are replaced by X to prevent pmatch complaining.

  The final part of the script does a tiny pmatch test run to reveal any problems persisting in 
  the file that would prevent later full scale pmatches from running smoothly.

=head1 OPTIONS
  
  Options are to be set in GeneConf.pm
  The important ones for this script are:
     GB_REFSEQ      location of refseq file in fasta format
     GB_SPTR        location of swissprot file in fasta format
     GB_PFASTA      where to write the clean fasta file
     GB_PMATCH      location of the pmatch executable

     eg.
	    GB_REFSEQ      => '/work2/vac/GeneBuild/rf.fa',
	    GB_SPTR        => '/work2/vac/GeneBuild/sptr.fa',
	    GB_PFASTA      => '/work2/vac/GeneBuild/human_proteome.fa',
	    GB_PMATCH      => '/work2/vac/rd-utils/pmatch',
  
=cut

use Bio::EnsEMBL::Pipeline::GeneConf qw (
                                         GB_REFSEQ
                                         GB_SPTR
                                         GB_PFASTA
                                         GB_PMATCH
                                        );


my $refseq   = $GB_REFSEQ;
my $sptr     = $GB_SPTR;
my $protfile = $GB_PFASTA;
my $pmatch   = $GB_PMATCH;

if( defined $refseq && -e $refseq ) { &parse_refseq; }
if( defined $sptr   && -e $sptr )   { &parse_sptr; }

&test_protfile;

### END MAIN

sub parse_sptr {
print STDERR "here\n";
  open (IN, "<$sptr") or die "Can't open $sptr\n";
  open (OUT, ">>$protfile") or die "Can't open $protfile\n";
  
  while(<IN>){
    # eg >143G_HUMAN (Q9UN99) 14-3-3 protein gamma
    if(/^>\S+\s+\((\S+)\)/){

      if($1 eq 'P17013'){
	die("DYING: $sptr still contains P17013. \nThis will probably cause problems with pmatch.\nYou should REMOVE IT AND RERUN prepare_proteome!\n");
      }
	
      if($1 eq 'Q99784'){
	die("DYING: $sptr still contains Q99784. \nThis will probably cause problems with pmatch.\nYou should REMOVE IT AND RERUN prepare_proteome!\n");
      }
      print OUT ">$1\n";
    }
    else {
      print OUT $_;
    }
  }
  
  close IN;
  close OUT;

}

sub parse_refseq {

  open (IN, "<$refseq") or die "Can't open $refseq\n";
  open (OUT, ">$protfile") or die "Can't open $protfile\n";

  while(<IN>){
    # eg >gi|4501893|ref|NP_001094.1| actinin, alpha 2 [Homo sapiens]
    if(/^>/){
      if(/^>\w+\|\w+\|\w+\|(\S+)\|/){
	print OUT ">$1\n";
      }
      else {
	print OUT $_;
      }
    }
    else {
      # sequence - sub U by X
      s/U/X/g;
      print OUT $_;
    }
  }
  close IN;
  close OUT;

}

sub test_protfile {

  # set up a temporary file
  my $time = time;
  chomp ($time);
  my $tmpfile = "cup.$$.$time.fa";
  open (SEQ, ">$tmpfile") or die "can't open $tmpfile\n";
  print SEQ ">test_seq\n";
  print SEQ 'cctgggctgcctggggaagcacccagggccagggagtgtgaccctgcaggctccacacaggactgccagaggcacac';
  close SEQ;

  # do a pmatch test run
  print "starting pmatch test ... \n";
  open(PM, "$pmatch -D $protfile $tmpfile | ") or die "Can't run $pmatch\n";
  while(<PM>) {
    print $_;
  }
  close PM;

  # tidy up
  unlink $tmpfile;

}

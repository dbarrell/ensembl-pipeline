

package Bio::EnsEMBL::Pipeline::RunnableDB::Finished_Est2Genome;

use Bio::EnsEMBL::Pipeline::RunnableDB;
use Bio::Root::RootI;
use Bio::EnsEMBL::Pipeline::SeqFetcher::Pfetch;
use Bio::EnsEMBL::Pipeline::SeqFetcher::Getseqs;
use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Pipeline::Runnable::Finished_MiniEst2Genome;

require "Bio/EnsEMBL/Pipeline/GB_conf.pl";

@ISA = qw(Bio::EnsEMBL::Pipeline::RunnableDB);


=head2 new

  Arg [1]   : 
  Function  : makes a new Finished_Est2Genome object with varibles defined from parameters hash 
  Returntype: $self 
  Exceptions: none
  Caller    : 
  Example   : 

=cut



sub new {
    my ($new,@args) = @_;
    my $self = $new->SUPER::new(@args);    
           
    # dbobj, input_id, seqfetcher, and analysis objects are all set in
    # in superclass constructor (RunnableDB.pm)

    $self->{'_fplist'} = []; #create key to an array of feature pairs
    my $seqfetcher = $self->make_seqfetcher($self->analysis->db);
    #print $seqfetcher."\n"; 
    $self->seqfetcher($seqfetcher);
	
    return $self;
}


=head2 fetch_input

  Arg [1]   : none
  Function  : fetches contig and feature information from the database and creates sts_gss runnable
  Returntype: none
  Exceptions: throws if not given a contig inputId
  Caller    : 
  Example   : 

=cut



sub fetch_input {
  my( $self) = @_;
  
  my @fps;
  my %ests;
  my @estseqs;
  $self->throw("No input id") unless defined($self->input_id);
  
  my $contigid  = $self->input_id;
  my $contig    = $self->dbobj->get_Contig($contigid);
 
  my $genseq   = $contig->primary_seq;
  my $type = $self->analysis->parameters;
  my @features = $contig->get_all_SimilarityFeatures_above_score($type, 200, 0);
 
  
  foreach my $f (@features) {
    if ($f->isa("Bio::EnsEMBL::FeaturePair") && 
	defined($f->hseqname))  {
      push(@fps, $f);
    }
  }
  
   
  my $filter;
  my $feat = $fps[0];
  if($feat->percent_id){
    $filter = 1;
  }else{
    $filter = undef;
  }
  my $tandem = 1;
 
  my $no_blast = 1;
  my $runnable = Bio::EnsEMBL::Pipeline::Runnable::STS_GSS->new('-unmasked' => $genseq,
								'-features' => \@fps,
								'-seqfetcher' => $self->seqfetcher,
								'-no_blast' => $no_blast,
								'-percent_filter' => $filter
								'-tandem_check' => $tandem);
  
  $self->runnable($runnable);
 
      
  
}
    
    
 
=head2 runnable

  Arg [1]   : runnable object
  Function  : sets runnable varible to runnable passed
  Returntype: runnable object
  Exceptions: if arg passed isn't a runnableI object'
  Caller    : 
  Example   : 

=cut

   



sub runnable {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->throw("[$arg] is not a Bio::EnsEMBL::Pipeline::RunnableI") unless $arg->isa("Bio::EnsEMBL::Pipeline::RunnableI");
	
	$self->{_runnable} = $arg;
    }

    return $self->{_runnable};
}


=head2 run

  Arg [1]   : none 
  Function  : runs runnable and pushes output onto output array
  Returntype: none
  Exceptions: throws if hasn't got a runnable'
  Caller    : 
  Example   : 

=cut


sub run {
    my ($self) = @_;

    my $runnable = $self->runnable;
    $runnable || $self->throw("Can't run - no runnable object");
   
    $runnable->run;
    push (@{$self->{'_output'}}, $runnable->output);
    foreach my $f(@{$self->{'_output'}}){
      $f->source_tag($self->analysis->db);
    }
}


=head2 output

  Arg [1]   : none
  Function  : returns output array
  Returntype: 
  Exceptions: none
  Caller    : 
  Example   : 

=cut


sub output {
    my ($self) = @_;
    return @{$self->{_output}};
}


=head2 make_seqfetcher

  Arg [1]   :  none
  Function  : makes a seqfetcher object. If a index db is defined a getseqs obj is made otherwise a pfetch obj is made
  Returntype: seqfetcher object
  Exceptions: none
  Caller    : 
  Example   : 

=cut



sub make_seqfetcher {
  my ( $self, $index_name ) = @_;
  my $index = undef;
  if(defined $index_name && ne ''){
    $index   = $ENV{BLASTDB}."/".$index_name;
  }
  my $seqfetcher;
  if(defined $index && $index ne ''){
    my @db = ( $index );
    $seqfetcher = Bio::EnsEMBL::Pipeline::SeqFetcher::Getseqs->new('-db' => \@db,);
  }
  else{
    # default to Pfetch
   
    $seqfetcher = new Bio::EnsEMBL::Pipeline::SeqFetcher::Pfetch;
  }
  return $seqfetcher;

}


1;

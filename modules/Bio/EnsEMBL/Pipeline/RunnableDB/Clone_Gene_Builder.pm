#!/usr/local/bin/perl

#
#
# Cared for by Michele Clamp  <michele@sanger.ac.uk>
#
# Copyright Michele Clamp
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=pod 

=head1 NAME

Bio::EnsEMBL::Pipeline::RunnableDB::AlignFeature

=head1 SYNOPSIS

    my $obj = Bio::EnsEMBL::Pipeline::RunnableDB::Est2Genome->new(
					     -dbobj     => $db,
					     -input_id  => $id
                                             );
    $obj->fetch_input
    $obj->run

    my @newfeatures = $obj->output;


=head1 DESCRIPTION

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::EnsEMBL::Pipeline::RunnableDB::Clone_Gene_Builder;

use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI;

use Bio::EnsEMBL::Pipeline::RunnableDBI;
use Bio::EnsEMBL::Pipeline::GeneBuilder;
use Bio::EnsEMBL::DB::ConvertibleVirtualContig;
use Bio::EnsEMBL::DBSQL::StaticGoldenPathAdaptor;
use Bio::EnsEMBL::DBLoader;
use Bio::EnsEMBL::Utils::GTF_handler;
use Bio::EnsEMBL::Pipeline::GeneConf qw (EXON_ID_SUBSCRIPT
					 TRANSCRIPT_ID_SUBSCRIPT
					 GENE_ID_SUBSCRIPT
					 PROTEIN_ID_SUBSCRIPT
					 );
use Data::Dumper;

@ISA = qw(Bio::EnsEMBL::Pipeline::RunnableDBI Bio::Root::RootI);

sub _initialize {
    my ($self,@args) = @_;
    my $make = $self->SUPER::_initialize(@_);    
           
    $self->{'_fplist'} = []; #create key to an array of feature pairs
    
    my( $dbobj,$input_id,$vcontig,$extend ) = $self->_rearrange([qw(DBOBJ INPUT_ID VCONTIG EXTEND)], @args);
       
    $self->throw("No database handle input")           unless defined($dbobj);
    $self->throw("[$dbobj] is not a Bio::EnsEMBL::DB::ObjI") unless $dbobj->isa("Bio::EnsEMBL::DB::ObjI");
    $self->dbobj($dbobj);

    $self->throw("No input id input") unless defined($input_id);
    $self->input_id($input_id);

    $vcontig = 1 unless defined($vcontig);
    
    $self->vcontig($vcontig);
    $self->extend($extend);

    return $self; # success - we hope!
}

sub input_id {
    my ($self,$arg) = @_;
    
    if (defined($arg)) {
	$self->{_input_id} = $arg;
    }
    
    return $self->{_input_id};
}

=head2 dbobj

    Title   :   dbobj
    Usage   :   $self->dbobj($db)
    Function:   Get/set method for database handle
    Returns :   Bio::EnsEMBL::Pipeline::DB::ObjI
    Args    :   

=cut

sub dbobj {
    my( $self, $value ) = @_;    
    if ($value) {

        $value->isa("Bio::EnsEMBL::DB::ObjI") || $self->throw("Input [$value] isn't a Bio::EnsEMBL::DB::ObjI");
        $self->{'_dbobj'} = $value;
    }
    return $self->{'_dbobj'};
}

=head2 fetch_output

    Title   :   fetch_output
    Usage   :   $self->fetch_output($file_name);
    Function:   Fetchs output data from a frozen perl object
                stored in file $file_name
    Returns :   array of exons (with start and end)
    Args    :   none

=cut

sub fetch_output {
    my($self,$output) = @_;
    
}

=head2 write_output

    Title   :   write_output
    Usage   :   $self->write_output
    Function:   Writes output data to db
    Returns :   array of exons (with start and end)
    Args    :   none

=cut


sub write_output {
    my($self) = @_;

    my @genes = $self->output;

    my $db = $self->dbobj;
  
    if( !defined $db ) {
      $self->throw("unable to make write db");
    }
    
    my %contighash;
    my $gene_obj = $db->gene_Obj;

    my $genebuilders = $self->get_genebuilders;
    my ($contig) = keys %$genebuilders;
    my $vc = $genebuilders->{$contig}->contig;


    return unless ($#genes >= 0);
    my @newgenes;
    
    foreach my $gene (@genes) {
      eval {
	print STDERR "Converting gene " . $gene->id . "\n";
	my $newgene = $vc->convert_Gene_to_raw_contig($gene);
	push(@newgenes,$newgene);
      };
      if ($@) {
	print STDERR "ERROR converting gene " . $gene->id . " " . $gene->type . " [$@]\n";
      }
    }
    # get new ids
    eval {

	my $genecount  = 0;
	my $transcount = 0;
	my $translcount = 0;
	my $exoncount  = 0;

	# get counts of each type of ID we need.

	foreach my $gene ( @newgenes ) {
	    $genecount++;
	    foreach my $trans ( $gene->each_Transcript ) {
		$transcount++;
		$translcount++;
	    }
	    foreach my $exon ( $gene->each_unique_Exon() ) {
	        $exon->seqname($vc->id);
		$exoncount++;
		foreach my $sf($exon->each_Supporting_Feature) {
                  if ($sf->isa("Bio::EnsEMBL::FeaturePair")) {
		  print STDERR "***sub_align: " . 
		               $sf->seqname . "\t" .
		               $sf->start . "\t" .
			       $sf->end . "\t" .
			       $sf->strand . "\t" .
			       $sf->hseqname . "\t" .
			       $sf->hstart . "\t" .
			       $sf->hend . "\n";
                 }
	  }

	    }
	}

	# get that number of ids. This locks the database

	my @geneids   =  $gene_obj->get_New_external_id('gene',$GENE_ID_SUBSCRIPT,$genecount);
	my @transids  =  $gene_obj->get_New_external_id('transcript',$TRANSCRIPT_ID_SUBSCRIPT,$transcount);
	my @translids =  $gene_obj->get_New_external_id('translation',$PROTEIN_ID_SUBSCRIPT,$translcount);
	my @exonsid   =  $gene_obj->get_New_external_id('exon',$EXON_ID_SUBSCRIPT,$exoncount);

	# database locks are over.

	# now assign ids. gene and transcripts are easy. Exons are harder.
	# the code currently assummes that there is one Exon object per unique
	# exon id. This might not always be the case.

	foreach my $gene ( @newgenes ) {
	    $gene->id(shift(@geneids));
	    my %exonhash;
	    foreach my $exon ( $gene->each_unique_Exon() ) {

		my $tempid = $exon->id;
		$exon->id(shift(@exonsid));
		$exonhash{$tempid} = $exon->id;
	    }
	    foreach my $trans ( $gene->each_Transcript ) {
		$trans->id(shift(@transids));
		$trans->translation->id(shift(@translids));
		$trans->translation->start_exon_id($exonhash{$trans->translation->start_exon_id});
		$trans->translation->end_exon_id($exonhash{$trans->translation->end_exon_id});
	    }
	    
	}

	# paranoia!
	if( scalar(@geneids) != 0 || scalar(@exonsid) != 0 || scalar(@transids) != 0 || scalar (@translids) != 0 ) {
	    $self->throw("In id assignment, left with unassigned ids ".scalar(@geneids)." ".scalar(@transids)." ".scalar(@translids)." ".scalar(@exonsid));
	}

    };
    if( $@ ) {
	$self->throw("Exception in getting new ids. Exiting befor write\n\n$@" );
    }


    # this now assummes that we are building on a single VC.

#    $self->throw("Bailing before real write\n");
    
  GENE: foreach my $gene (@newgenes) {	
      # do a per gene eval...
      eval {
	  
	  $gene_obj->write($gene,'evidence');
      }; 
      if( $@ ) {
	  print STDERR "UNABLE TO WRITE GENE\n\n$@\n\nSkipping this gene\n";
      }
	    
  }
  }
sub old_write {
  my ($self,@genes) = @_;

#    my $dblocator = "Bio::EnsEMBL::DBSQL::Obj/host=ensrv4.sanger.ac.uk;dbname=arne_freeze05_ewan;user=ensadmin";
    
#    my $db = Bio::EnsEMBL::DBLoader->new($dblocator);
   
#    if( !defined $db ) {
#	$self->throw("unable to make write db");
#    }

    my $db = $self->dbobj;

    my %contighash;
    my $gene_obj = $db->gene_Obj;

    # this now assummes that we are building on a single VC.

    my $genebuilders = $self->get_genebuilders;
    my ($contig) = keys %$genebuilders;
    my $vc = $genebuilders->{$contig}->contig;

    return unless ($#genes >= 0);
    my @newgenes;

     foreach my $gene (@genes) { 
       eval {
	 my $newgene = $vc->convert_Gene_to_raw_contig($gene);
	 push(@newgenes,$newgene);
       };
       if ($@) {
	 print STDERR "ERROR converting gene " . $gene->id . " " . $gene->type . "\n";
       }
     }


    eval {

        foreach my $gene (@newgenes) {	

	    # do a per gene eval...
	    eval {
    
		$gene->type('pruned');
		
		my ($geneid) = $gene_obj->get_New_external_id('gene',$GENE_ID_SUBSCRIPT,1);
		
		$gene->id($geneid);
		print (STDERR "Writing gene " . $gene->id . "\n");
		
		# Convert all exon ids and save in a hash
		my %namehash;
		my @exons = $gene->each_unique_Exon();
		my @exonids = $gene_obj->get_New_external_id('exon',$EXON_ID_SUBSCRIPT,scalar(@exons));
		my $count = 0;
		foreach my $ex (@exons) {
		    $namehash{$ex->id} = $exonids[$count];
		    $ex->id($exonids[$count]);
		    print STDERR "Exon id is ".$ex->id."\n";
		    $count++;
		}
		
		my @transcripts = $gene->each_Transcript;
		my @transcript_ids = $gene_obj->get_New_external_id('transcript',$TRANSCRIPT_ID_SUBSCRIPT,scalar(@transcripts));
		my @translation_ids = $gene_obj->get_New_external_id('translation',$PROTEIN_ID_SUBSCRIPT,scalar(@transcripts));
		$count = 0;
		foreach my $tran (@transcripts) {
		    $tran->id             ($transcript_ids[$count]);
		    $tran->translation->id($translation_ids[$count]);
		    $count++;
		    
		    my $translation = $tran->translation;
		    
		    print (STDERR "Transcript  " . $tran->id . "\n");
		    print (STDERR "Translation " . $tran->translation->id . "\n");
		    
		    foreach my $ex ($tran->each_Exon) {
			my @sf = $ex->each_Supporting_Feature;
			print STDERR "Supporting features are " . scalar(@sf) . "\n";
			
			if ($namehash{$translation->start_exon_id} ne "") {
			    $translation->start_exon_id($namehash{$translation->start_exon_id});
			}
			if ($namehash{$translation->end_exon_id} ne "") {
			    $translation->end_exon_id  ($namehash{$translation->end_exon_id});
			}
			print(STDERR "Exon         " . $ex->id . "\n");
		    }
		    
		}
		
		$gene_obj->write($gene);
	    }; 
	    if( $@ ) {
		print STDERR "UNABLE TO WRITE GENE\n\n$@\n\nSkipping this gene\n";
	    }
	    
	}
    };
    if ($@) {

	    $self->throw("Error writing gene for " . $self->input_id . " [$@]\n");
	} else {
	    # nothing
	}


     # Set attribute tag on all contigs
     $db->extension_tables(1);

     foreach my $contig (keys %$genebuilders) {
        my @contigs = $vc->get_all_RawContigs;

        foreach my $contig (@contigs) {
            $contig->set_attribute('GENE_BUILD_NOV05',1); 
        }
     }
}

=head2 fetch_input

    Title   :   fetch_input
    Usage   :   $self->fetch_input
    Function:   Fetches input data for est2genome from the database
    Returns :   nothing
    Args    :   none

=cut

sub fetch_input {
    my( $self) = @_;

    $self->throw("No input id") unless defined($self->input_id);

    $self->dbobj->static_golden_path_type('CLONE');

    my $stadaptor = $self->dbobj->get_StaticGoldenPathAdaptor();

    my $fpcid  = $self->input_id;
    
    print STDERR "FPC contig $fpcid\n";
    my $contig    = $stadaptor->fetch_VirtualContig_by_fpc_name($fpcid);

    $contig->primary_seq;

    print STDERR "Length of primary seq is ",$contig->primary_seq->length,"\n";

    my $genebuilder = new Bio::EnsEMBL::Pipeline::GeneBuilder(-contig => $contig,
							      -input_id => $self->input_id,
							      );


    
    $self->addgenebuilder($genebuilder,$contig);

}

sub vcontig {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_vcontig} = $arg;
    }

    return $self->{_vcontig};
}

sub extend {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_extend} = $arg;
    }

    return $self->{_extend} || 400000;
}

sub addgenebuilder {
    my ($self,$arg,$contig) = @_;

    if (defined($arg) && defined($contig)) {
	$self->{_genebuilder}{$contig->id} = $arg;
    } else {
	$self->throw("Wrong number of inputs [$arg,$contig]\n");
    }
}

sub get_genebuilders {
    my ($self) = @_;

    return $self->{_genebuilder};
}

sub check_gene {
   my ($self,$gene) = @_;

   foreach my $tran ($gene->each_Transcript) {
      my $seq = $tran->translate->seq;

      if ($seq =~ /\*/) {
        $self->throw("Stop codons in gene " . $gene->id . " transcript " . $tran->id . " - exiting");
      }
   }
}
	
sub run {
    my ($self) = @_;

    my $genebuilders = $self->get_genebuilders;
    #my @gene;

    $self->{_output} = [];
    
    my @vcgenes;
    foreach my $contig (keys %$genebuilders) {
        my $vc = $genebuilders->{$contig}->contig;
	print(STDERR "Building for $contig\n");
	$genebuilders->{$contig}->build_Genes;
	@vcgenes = @{$genebuilders->{$contig}{_genes}};
        print STDERR "Genes before conversion\n";
#	$vc->_dump_map(\*STDERR);
        $genebuilders->{$contig}->print_Genes(@vcgenes);
        print STDERR "Converting coordinates";
        #foreach my $g (@vcgenes) {
        #   my $newgene = $vc->convert_Gene_to_raw_contig($g);
           #$self->check_gene($newgene);
	#   push(@gene,$newgene);
        #}
    }
    
	    
    push(@{$self->{_output}},@vcgenes);
}

sub output {
    my ($self) = @_;

    if (!defined($self->{_output})) {
	$self->{_output} = [];
    }
    return @{$self->{_output}};
}


1;







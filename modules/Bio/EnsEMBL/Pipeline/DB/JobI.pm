#
# Object for storing details of an analysis job
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

Bio::EnsEMBL::Pipeline::DB::JobI

=head1 SYNOPSIS

=head1 DESCRIPTION

Interface for storing run and status details of an analysis job

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::EnsEMBL::Pipeline::JobI;

use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI;

use Bio::Root::RootI;

# Inherits from the base bioperl object
@ISA = qw(Bio::Root::RootI);


=head2 id

  Title   : id
  Usage   : $self->id($id)
  Function: Get/set method for the id of the job itself
            This will usually be generated by the
            back end database the jobs are stored in
  Returns : int
  Args    : int

=cut


sub id {
    my ($self) = @_;

    $self->throw("Method id not implemented");
}

=head2 input_id

  Title   : input_id
  Usage   : $self->input_id($id)
  Function: Get/set method for the id of the input to the job
  Returns : int
  Args    : int

=cut


sub input_id {
    my ($self) = @_;

    $self->throw("Method input_id not implemented");
}

=head2 analysis

  Title   : analysis
  Usage   : $self->analysis($anal);
  Function: Get/set method for the analysis object of the job
  Returns : Bio::EnsEMBL::Pipeline::Analysis
  Args    : bio::EnsEMBL::Pipeline::Analysis

=cut


sub analysis {
    my ($self) = @_;

    $self->throw("Method analysis not implemented");
}


=head2 LSF_id

  Title   : LSF_id
  Usage   : $self->LSF_id($id)
  Function: Get/set method for the LSF id of the job
  Returns : int
  Args    : int

=cut


sub LSF_id {
    my ($self) = @_;

    $self->throw("Method input_id not implemented");
}

=head2 queue

  Title   : queue
  Usage   : $self->queue
  Function: Get/set method for the LSF queue name
  Returns : String
  Args    : String

=cut

sub queue {
    my ($self) = @_;

    $self->throw("Method queue not implemented");
}


=head2 machine

  Title   : machine
  Usage   : $self->machine($machine)
  Function: Get/set method for the machine the job is running on
  Returns : string
  Args    : string

=cut

sub machine {
    my ($self) = @_;

    $self->throw("Method machine not implemented");
}



=head2 submit

  Title   : submit
  Usage   : $self->submit
  Function: Submits the job to the specified LSF queue
  Returns : 
  Args    : 

=cut

sub submit {
    my ($self) = @_;

    $self->throw("Method submit not implemented");
}

=head2 store

  Title   : store
  Usage   : $self->store
  Function: Stores the job object as a persistent object
  Returns : nothing
  Args    : none

=cut

sub store {
    my ($self) = @_;

    $self->throw("Method store not implemented");
}


=head2 freeze

  Title   : freeze
  Usage   : $self->freeze
  Function: Freezes the object into a string
  Returns : String
  Args    : None

=cut

sub freeze {
    my ($self) = @_;

    $self->throw("Method freeze not implemented");
}


=head2 submission_checks

  Title   : submission_checks
  Usage   : $self->submission_checks
  Function: After submission to the LSF queue when 
            the wrapper script is run - these are
            the checks to run (on binaries,databases etc)
            before the job is run.
  Returns : String
  Args    : None

=cut

sub submission_checks {
    my ($self) = @_;

    $self->throw("Method submission_checks not implemented");
}



=head2 current_status

  Title   : current_status
  Usage   : my $status = $job->current_status
  Function: Get/set method for the current status
  Returns : Bio::EnsEMBL::Pipeline::Status
  Args    : Bio::EnsEMBL::Pipeline::Status

=cut

sub current_status {
    my ($self) = @_;

    $self->throw("Method current_status not implemented");
}

=head2 get_all_status

  Title   : get_all_status
  Usage   : my @status = $job->get_all_status
  Function: Get all status objects associated with this job
  Returns : @Bio::EnsEMBL::Pipeline::Status
  Args    : @Bio::EnsEMBL::Pipeline::Status

=cut

sub get_all_status {
    my ($self) = @_;

    $self->throw("Method get_all_status not implemented");
}



=head2 stdout_file

  Title   : stdout_file
  Usage   : my $file = $self->stdout_file
  Function: Get/set method for stdout.
  Returns : string
  Args    : string

=cut

sub stdout_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_stdout_file} = $arg;
    }
    return $self->{_stdout_file};
}

=head2 stderr_file

  Title   : stderr_file
  Usage   : my $file = $self->stderr_file
  Function: Get/set method for stderr.
  Returns : string
  Args    : string

=cut

sub stderr_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_stderr_file} = $arg;
    }
    return $self->{_stderr_file};
}

=head2 output_file

  Title   : output_file
  Usage   : my $file = $self->output_file
  Function: Get/set method for output
  Returns : string
  Args    : string

=cut

sub output_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_output_file} = $arg;
    }
    return $self->{_output_file};
}


=head2 input_object_file

  Title   : intput_object_file
  Usage   : my $file = $self->input_object_file
  Function: Get/set method for the input object file
  Returns : string
  Args    : string

=cut

sub input_object_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_input_object_file} = $arg;
    }
    return $self->{_input_object_file};
}

=head2 status_file

  Title   : status_file
  Usage   : my $file = $self->status_file
  Function: Get/set method for the status file
  Returns : string
  Args    : string

=cut

sub status_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
        $self->{_status_file} = $arg;
    }
    return $self->{_status_file};
}


use lib 't/pipeline';
use strict;
use warnings;

BEGIN { $| = 1;
	use Test ;
	plan tests => 5;
}

use TestUtils qw(debug test_getter_setter);

use Bio::EnsEMBL::Pipeline::TaskStatus;
use Bio::EnsEMBL::Pipeline::IDSet;

my $created = Bio::EnsEMBL::Pipeline::IDSet->new( -ID_LIST => [1, 2, 3, 4, 5]);

my $listref = [6, 7, 8, 9, 10];

my $taskstatus = Bio::EnsEMBL::Pipeline::TaskStatus->new( 
						         -CREATED => $created,
						         -SUBMITTED => $listref,
						         );


ok($taskstatus);
   
my $more_created = Bio::EnsEMBL::Pipeline::IDSet->new(
						      -ID_LIST => [11, 12],	
						     );

ok($taskstatus->add_created($more_created));


$taskstatus->create_existing;

ok($taskstatus->get_existing);

my $existing = $taskstatus->get_existing;

ok($existing);

my $ref = $existing->ID_list;

my @list = @$ref;

ok(@list == 12)


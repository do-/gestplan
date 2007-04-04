################################################################################

sub get_type {

	$type = $_REQUEST {type};	
	$type ||= 'zones';

	return $type;

}

1;

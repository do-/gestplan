################################################################################

sub do_create_prestation_models {
	
	do_create_DEFAULT ();
	esc ();		

}

################################################################################

sub do_delete_prestation_models {
	
	sql_do_delete ('prestation_models');

}

################################################################################

sub validate_create_prestation_models {
	
	$_REQUEST {id_prestation_type} or return "Vouz avez oublié de choisir le type de prestation";

    $_REQUEST {day_finish}  ||= $_REQUEST {day_start};
    $_REQUEST {half_finish} ||= $_REQUEST {half_start};
    
    $_REQUEST {fake} = 0;

	return undef;
	
}

################################################################################

sub get_item_of_prestation_models {
	

	my $item = sql_select_hash ('prestation_models');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

#	add_vocabularies ($item, '???', '???', {order => "id", filter => "id=$$data{id_prestation_models}"} ...);

	$item -> {path} = [
		{type => 'prestation_models', name => '???'},
		{type => 'prestation_models', name => $item -> {label}, id => $item -> {id}},
	];
	
	return $item;
	
}

1;

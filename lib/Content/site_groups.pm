

################################################################################

sub validate_update_site_groups {

	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'entrer la désignation";

	undef;
	
}

################################################################################

sub get_item_of_site_groups { # Secteurs

	my $data = sql ('site_groups');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $data -> {fake} > 0);

	return $data;

}

################################################################################

sub do_create_site_groups {

	$_REQUEST {id} = sql_do_insert (site_groups => {

		id_organisation => $_USER -> {id_organisation},

	});

}

################################################################################

sub select_site_groups { # Secteurs

	sql (
	
		{},
		
		site_groups => [
	
			[id_organisation => $_USER -> {id_organisation}],
			
			['label LIKE %?%' => $_REQUEST {q}],
			
			[ LIMIT => 'start, 50'],
		
		],
				
	);	

}

1;

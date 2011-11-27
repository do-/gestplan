
################################################################################

sub do_create_models {

	$_REQUEST {id} = sql_do_insert (models => {
		id_organisation          => $_REQUEST {id_organisation},
		is_odd                   => -1,
	});

}

################################################################################

sub do_update_models {

	$_REQUEST {_label} or die "#_label#:Vous avez oublié de nommer cette semaine modèle";
	
	do_update_DEFAULT ();

}

################################################################################

sub get_item_of_models { #

	my $data = sql (models => $_REQUEST {id}, 'organisations');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $data -> {fake} > 0);
	
	$data -> {voc_oddities} = sql_select_all ('SELECT id % 2 AS id, label FROM voc_oddities ORDER BY 1');
	
	return $data;

}

################################################################################

sub select_models {

	$_REQUEST {id_organisation} ||= $_USER -> {id_organisation} || -1;

	sql (
	
		{},
		
		models => [
	
			'id_organisation',
			
			['label LIKE %?%' => $_REQUEST {q}],
			
			[ LIMIT => 'start, 50'],
		
		],
		
		'voc_oddities ON models.is_odd = voc_oddities.id % 2',
		
	);	

}

1;

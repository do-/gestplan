################################################################################

sub recalculate_sites {

	send_refresh_messages ();

}

################################################################################

sub do_update_sites {
	
	sql_do_update ('sites', [qw(
		label
		ord
		id_site_group
	)]);

}

################################################################################

sub do_create_sites {	

	$_REQUEST {id} = sql_do_insert ('sites', {
		id_organisation => $_USER -> {id_organisation},
	});

}

################################################################################

sub get_item_of_sites {

	my $item = sql_select_hash ('sites');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);
	
	$_REQUEST {__read_only} or $item -> {ord} ||= 10 + sql ('sites(MAX(ord))' => [[id_organisation => $_USER -> {id_organisation}]]);
	
	$item -> {path} = [
		{type => 'sites', name => 'Onglets'},
		{type => 'sites', name => $item -> {label}, id => $item -> {id}},
	];

	add_vocabularies ($item,
	
		site_groups => {filter => "id_organisation = $_USER->{id_organisation}"},
	
	),

	return $item;
	
}

################################################################################

sub select_sites {

	sql (
	
		add_vocabularies ({},
	
			site_groups => {filter => "id_organisation = $_USER->{id_organisation}"},
	
		),

		sites => [
		
			['label LIKE %?%' => $_REQUEST {q}],
			[ id_organisation => $_USER -> {id_organisation}],
			[ ORDER           => 'ord,label'],
			[ LIMIT           => "start, $conf->{portion}"],
		
		],
		
		'site_groups',		
		
	)
	
}

1;

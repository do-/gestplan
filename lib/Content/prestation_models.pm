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

	my $type = sql_select_hash ('prestation_types', $_REQUEST {id_prestation_type});
	
	my @ids_rooms = grep {$_ > 0} split /\,/, $type -> {ids_rooms};
	
	if (@ids_rooms) {
	
		my $filter = join ' OR ', map {"ids_rooms LIKE '\%,$_,\%'"} @ids_rooms;
		
		$filter = "($filter)";
				
		$filter .= " AND id <> $_REQUEST{id_prestation_type}" if $type -> {is_collective};
		
		my $ids_conflicting_types = sql_select_ids ("SELECT id FROM prestation_types WHERE fake = 0 AND $filter");
		
		my $conflict = sql_select_hash (<<EOS, $_REQUEST {id_user}, $_REQUEST {day_start}, $_REQUEST {half_start}, $_REQUEST {is_odd});
			SELECT
				prestation_models.*
				, users.label
				, prestation_types.ids_rooms
			FROM
				prestation_models
				LEFT JOIN users ON prestation_models.id_user = users.id
				LEFT JOIN prestation_types ON prestation_models.id_prestation_type = prestation_types.id
			WHERE
				prestation_models.id_user <> ?
				AND prestation_models.day_start = ?
				AND prestation_models.half_start = ?
				AND prestation_models.is_odd = ?
				AND prestation_models.id_prestation_type IN ($ids_conflicting_types)
			LIMIT 1
EOS
	
		if ($conflict -> {id}) {
		
			my $room;
			
			foreach my $id_room (@ids_rooms) {
			
				$conflict -> {ids_rooms} =~ /\,$id_room\,/ or next;
				
				$room = sql_select_hash ('rooms', $id_room);
				
				last;
				
			}
		
			return "Conflit pour la salle nommée '$room->{label}' avec $conflict->{label}";
		
		}
	
	}	

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

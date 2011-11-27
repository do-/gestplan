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

	my $model = sql (models => $_REQUEST {id_model});

	$_REQUEST {is_odd} = $model -> {is_odd};

	my $type = sql_select_hash ('prestation_types', $_REQUEST {id_prestation_type});
	
	my @ids_rooms = grep {$_ > 0} split /\,/, $type -> {ids_rooms};
	
	if (@ids_rooms) {
	
		my $filter = join ' OR ', map {"ids_rooms LIKE '\%,$_,\%'"} @ids_rooms;
		
		$filter = "($filter)";
				
		$filter .= " AND id <> $_REQUEST{id_prestation_type}" if $type -> {is_collective};
		
		my $ids_conflicting_types = sql_select_ids ("SELECT id FROM prestation_types WHERE fake = 0 AND $filter");

		my $conflict = sql_select_hash (<<EOS, $_REQUEST {id_user}, $_REQUEST {day_start}, $_REQUEST {half_start}, $_REQUEST {id_model});
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
				AND prestation_models.id_model = ?
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
		
			return "Conflit pour la ressource nommée '$room->{label}' avec $conflict->{label}";
		
		}
	
	}	

    	$_REQUEST {day_finish}  ||= $_REQUEST {day_start};
    	$_REQUEST {half_finish} ||= $_REQUEST {half_start};
    
    	$_REQUEST {_fake} = 0;

	return undef;
	
}

1;

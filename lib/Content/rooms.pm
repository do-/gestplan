################################################################################

sub recalculate_rooms {

	send_refresh_messages ();

}

################################################################################

sub do_update_rooms {

	sql_do_update ('rooms', [qw(
		label
		id_site
	)]);

}

################################################################################

sub do_create_rooms {	

	$_REQUEST {id} = sql_do_insert ('rooms', {
		id_organisation => $_USER -> {id_organisation},
	});

}

################################################################################

sub get_item_of_rooms {

	my $item = sql_select_hash ('rooms');

	add_vocabularies ($item,
		sites => {filter => "id_organisation = $_USER->{id_organisation}"},
	);

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'rooms', name => 'Ressources'},
		{type => 'rooms', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
	
}

################################################################################

sub select_rooms {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($rooms, $cnt) = sql_select_all_cnt (<<EOS, $q, $_USER -> {id_organisation}, {fake => 'rooms'});
		SELECT
			rooms.*
			, sites.label AS site_label
		FROM
			rooms
			LEFT JOIN sites ON rooms.id_site = sites.id
		WHERE
			(rooms.label LIKE ?)
			AND rooms.id_organisation = ?
		ORDER BY
			rooms.label
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		rooms => $rooms,
		cnt => $cnt,
		portion => $$conf{portion},
	};
	
}

1;

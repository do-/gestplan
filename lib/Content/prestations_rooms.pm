################################################################################

sub do_update_prestations_rooms {

	sql_do_update ('prestations_rooms', [qw(
		id_room
		dt_start
		half_start
		dt_finish
		half_finish
	)]);

}

################################################################################

sub validate_update_prestations_rooms {
	
	$_REQUEST {_id_room} or return "#_id_room#:Veuillez choisir la salle";

	my @start  = vld_date ('dt_start');
	my @finish = vld_date ('dt_finish');
			
	if (Delta_Days (@start, @finish) < 0) {
		return "#_dt_finish#: L'ordre des dates est incorrect";
	}
	elsif (Delta_Days (@start, @finish) < 0 && $_REQUEST {_half_start} > $_REQUEST {_half_finish}) {
		return "#_half_finish#: L'ordre des périodes est incorrect";
	}
	
	my $item = sql_select_hash ('prestations_rooms');
	my $prestation = sql_select_hash ('prestations', $item -> {id_prestation});

	if ($_REQUEST {_dt_start} lt $prestation -> {dt_start}) {
		return "#_dt_start#: La date du commencement précède celle de la prestation";
	}	

	if ($_REQUEST {_dt_start} eq $prestation -> {dt_start} && $_REQUEST {_half_start} < $prestation -> {half_start}) {
		return "#_half_start#: Le temps du commencement précède celui de la prestation";
	}	

	if ($_REQUEST {_dt_finish} gt $prestation -> {dt_finish}) {
		return "#_dt_finish#: La date du finissement excède celle de la prestation";
	}	

	if ($_REQUEST {_dt_finish} eq $prestation -> {dt_finish} && $_REQUEST {_half_finish} > $prestation -> {half_finish}) {
		return "#_half_finish#: Le temps du finissement exccède celui de la prestation";
	}

	0 == sql_select_scalar (<<EOS, $_REQUEST {id}, $_REQUEST {_id_room}, $_REQUEST {_dt_finish} . $_REQUEST {_half_finish}, $_REQUEST {_dt_start} . $_REQUEST {_half_start}) or return "Désolé, mais la salle est occupée pendant cette période.";
		SELECT
			prestations_rooms.id
		FROM
			prestations_rooms
			INNER JOIN prestations ON prestations_rooms.id_prestation = prestations.id
		WHERE
			prestations_rooms.id <> ?
			AND prestations_rooms.id_room = ?
			AND prestations_rooms.fake = 0
			AND CONCAT(prestations_rooms.dt_start,  prestations_rooms.half_start)  <= ?
			AND CONCAT(prestations_rooms.dt_finish, prestations_rooms.half_finish) >= ?
		LIMIT
			1
EOS

	return undef;

}

################################################################################

sub do_delete_prestations_rooms {

	sql_do_delete ('prestations_rooms');

}

################################################################################

sub get_item_of_prestations_rooms {

	my $item = sql_select_hash ('prestations_rooms');
	
	__d ($item, 'dt_start', 'dt_finish');

	my $prestation = sql_select_hash ('prestations', $item -> {id_prestation});
	my $prestation_type = sql_select_hash ('prestation_types', $prestation -> {id_prestation_type});
	
	__d ($prestation, 'dt_start', 'dt_finish');

	my $user = sql_select_hash ('users', $prestation -> {id_user} . ' ' . $prestation -> {dt_start} . ' .. ' . $prestation -> {dt_finish});

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	add_vocabularies ($item,
#		'rooms'       => {filter => "id IN ($$prestation_type{ids_rooms})"},
		'rooms'       => {filter => "id_organisation = $$_USER{id_organisation}"},
		'day_periods' => {order  => 'id', filter => 'id < 3'},
	);

	$item -> {path} = [
		{type => 'prestations', name => 'Prestations'},
		{type => 'prestations', id => $prestation -> {id}, name => $user -> {label}},
		{type => 'prestations_rooms', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;

}

1;

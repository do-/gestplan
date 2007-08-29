################################################################################

sub validate_update_off_periods {
	
	my @start  = vld_date ('dt_start');
	my @finish = vld_date ('dt_finish');
	
	Delta_Days (@start, @finish) >= 0 or return "#_dt_finish#:Mauvais ordre des dates";
	
	my $item = sql_select_hash ('off_periods');

	my $conflict = sql_select_hash (
		'SELECT * FROM off_periods WHERE fake = 0 AND id <> ? AND id_user = ? AND CONCAT(dt_start, half_start) <= ? AND CONCAT(dt_finish, half_finish) >= ? ORDER BY dt_start DESC, half_start DESC LIMIT 1',
		$item -> {id},
		$item -> {id_user},
		$_REQUEST {_dt_finish} . $_REQUEST {_half_finish},
		$_REQUEST {_dt_start}  . $_REQUEST {_half_start},
	);
	
	if ($conflict -> {id}) {
	
		__d ($conflict, 'dt_start', 'dt_finish');
		
		sql_select_loop (
			'SELECT * FROM day_periods',
			sub {$conflict -> {day_periods} -> {$i -> {id}} = $i -> {label}}
		);
		
		return "Conflit : absence de $conflict->{dt_start} $conflict->{day_periods}->{$conflict->{half_start}} à $conflict->{dt_finish} $conflict->{day_periods}->{$conflict->{half_finish}}";
		
	}

	return undef;
	
}

################################################################################

sub get_item_of_off_periods {

	my $item = sql_select_hash ('off_periods');
	
	$item -> {half_start}  ||= 1;
	$item -> {half_finish} ||= 2;
	
	my $user = sql_select_hash ('users', $item -> {id_user});
	
	__d ($item, 'dt_start', 'dt_finish');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {day_periods} = [
		{id => 1, label => 'matin'},
		{id => 2, label => 'après-midi'},
	];

#	add_vocabularies ($item, '???', '???', ...);

	$item -> {path} = [
		{type => 'users', name => 'Utilisateurs'},
		{type => 'users', name => $user -> {label}, id => $user -> {id}},
		{type => 'off_periods', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
}

1;

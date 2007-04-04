################################################################################

sub validate_update_off_periods {
	
	my @start  = vld_date ('dt_start');
	my @finish = vld_date ('dt_finish');
	
	Delta_Days (@start, @finish) >= 0 or return "#_dt_finish#:Mauvais ordre des dates";

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

################################################################################

sub recalculate_organisations {

	send_refresh_messages ();

}

################################################################################

sub do_update_organisations {
	
		sql_do_update ('organisations', [qw(label ids_partners href days)]);

}

################################################################################

sub validate_update_organisations {
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'entrer la désignation";
	
	my @ids = get_ids ('ids_partners');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_partners} = join ',', @ids;

	my @ids = get_ids ('days');
	@ids > 0 or return "Vous n'avez indiqué aucune jour travaillée";
	$_REQUEST {_days} = join ',', @ids;

	return undef;
	
}

################################################################################

sub get_item_of_organisations {

	my $item = sql_select_hash ('organisations');
	
	$item -> {ids_partners} = [split /\,/, $item -> {ids_partners}];
	$item -> {days} = [split /\,/, $item -> {days}];
	
	add_vocabularies ($item,
		organisations => {filter => "id <> $$item{id}"},
	);

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	$item -> {path} = [
		{type => 'organisations', name => 'Structures'},
		{type => 'organisations', name => $item -> {label}, id => $item -> {id}},
	];
	
	my $q = '%' . $_REQUEST {q} . '%';
	
	my $start = $_REQUEST {start} + 0;
	$item -> {portion} = 50;
	
	($item -> {users}, $item -> {cnt})= sql_select_all_cnt (<<EOS, $q, $q, $item -> {id}, {fake => 'users'});
		SELECT
			users.*
			, roles.label  AS role_label
			, sites.label  AS site_label
			, groups.label AS group_label
		FROM
			users
			LEFT JOIN roles  ON users.id_role = roles.id
			LEFT JOIN sites  ON users.id_site = sites.id
			LEFT JOIN groups ON users.id_group = groups.id
		WHERE
			(users.label LIKE ? or users.login LIKE ?)
			AND users.id_organisation = ?
		ORDER BY
			users.label
		LIMIT
			$start, $item->{portion}
EOS

	return $item;
	
}

################################################################################

sub select_organisations {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($organisations, $cnt)= sql_select_all_cnt (<<EOS, $q, {fake => 'organisations'});
		SELECT
			organisations.*
		FROM
			organisations
		WHERE
			(organisations.label LIKE ?)
		ORDER BY
			organisations.label
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		organisations => $organisations,
		cnt => $cnt,
		portion => $$conf{portion},
	};
}

1;

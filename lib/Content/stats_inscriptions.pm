################################################################################

sub select_stats_inscriptions {
	
	my $organisation = sql_select_hash ('organisations', $_USER -> {id_organisation});	
	$organisation -> {ids_roles_inscriptions} =~ /\,$$_USER{id_role}\,/ or redirect ('/');

	my $sites = sql_select_vocabulary (sites => {filter => "id_organisation = $_USER->{id_organisation}"});

	my ($year) = Today;
	
	$_REQUEST {year} ||= $year;
	
	$_REQUEST {month} = 0 if $_REQUEST {id_user};
	
	my $prestation_types = sql_select_all ("SELECT * FROM prestation_types WHERE fake = 0 AND id_organisation = ? AND IFNULL(no_stats, 0) = 0 ORDER BY label_short", $_USER -> {id_organisation});
	my @ids = map {$_ -> {id}} @$prestation_types;
	my $ids = join ',', (-1, @ids);
	
	my $from = $_REQUEST {year} . '-01-01';
	my $to   = $_REQUEST {year} . '-12-31';
	
	if ($_REQUEST {month} > 0) {
		$from = sprintf ('%04d-%02d-%02d', $_REQUEST {year}, $_REQUEST {month}, 1);
		$to   = sprintf ('%04d-%02d-%02d', $_REQUEST {year}, $_REQUEST {month}, Days_in_Month ($_REQUEST {year}, $_REQUEST {month}));
	}
	
	my $user = 'IF(inscriptions.hour > 0, inscriptions.id_user, -1)';
	
	my $user_filter = $_REQUEST {id_user} ? " AND $user = $_REQUEST{id_user}" : '';
	
	if ($_REQUEST {id_site}) {
		my $ids_users = sql_select_ids ("SELECT id FROM users WHERE id_site = ?", $_REQUEST {id_site});
		$user_filter .= " AND prestations.id_user IN ($ids_users)";
	}

	my $prestations = sql_select_all (<<EOS, $from, $to);
		SELECT
			prestations.id_prestation_type
			, MONTH(prestations.dt_start) AS month
			, $user AS id_user
			, COUNT(inscriptions.id) AS cnt
		FROM
			inscriptions
			INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
		WHERE
			inscriptions.fake = 0
			AND prestations.id_prestation_type IN ($ids)
			AND prestations.dt_start BETWEEN ? AND ?
			$user_filter
		GROUP BY
			1, 2, 3
EOS

	my $filter = $_REQUEST {id_site} ? " AND id_site = $_REQUEST{id_site} " : '';

	my $users = sql_select_all (<<EOS, $_USER -> {id_organisation}, $from, $from, $to, $to);
		SELECT
			id
			, label
		FROM
			users
		WHERE
			id_organisation = ?
			AND users.id_group > 0
			AND IFNULL(users.dt_start, ?) <= ?
			AND IFNULL(users.dt_finish, ?) >= ?
			AND fake = 0
			$filter
		ORDER BY
			label
EOS

	push @$users, {id => -1, label => '[pas réalisés]'};
	
	my $lines =
		$_REQUEST {month} ? $users :
		[ map {{ id => $_, label => ucfirst $month_names [$_ - 1]}} (1 .. 12) ];
	
	my $id2line = {};	
	foreach (@$lines) {$id2line -> {$_ -> {id}} = $_};
	
	my $total = {label => 'Total', is_total => 1};
	
	foreach my $prestation (@$prestations) {
					
		my $line =
			$_REQUEST {month} ? $id2line -> {$prestation -> {id_user}} :
			$id2line -> {$prestation -> {month}};
		
		foreach ($line, $total) {
			$_ -> {by_type} -> {$prestation -> {id_prestation_type}} += $prestation -> {cnt};
			$_ -> {cnt} += $prestation -> {cnt};
		}		
						
	}
	
	push @$lines, $total;

	return {
		lines => $lines,
		users => [grep {$_ -> {id}} @$users],
		sites => $sites,
		prestation_types => $prestation_types,
		years => [map {{id => $_, label => $_}} (2005 .. $year)],
		months => [
			{id =>  0, label => "Toute l'année par mois"},
			{id => -1, label => "Toute l'année par utilisateur"},
			map {{
				id => $_,
				label => ucfirst $month_names [$_ - 1] . ' par utilisateur',
			}} (1 .. 12)
		],
	};

}

1;

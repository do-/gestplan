################################################################################

sub select_stats_prestations {

	my $organisation = sql_select_hash ('organisations', $_USER -> {id_organisation});	
	$organisation -> {ids_roles_prestations} =~ /\,$$_USER{id_role}\,/ or redirect ('/');

	my $sites = sql_select_vocabulary (sites => {filter => "id_organisation = $_USER->{id_organisation}"});

	my ($year) = Today;
	
	$_REQUEST {year} ||= $year;

	$_REQUEST {month} = 0 if $_REQUEST {id_user};
	
	my $rh_filter = $_REQUEST {is_rh} == 1 ? ' AND is_rh = 1 ' : $_REQUEST {is_rh} == -1 ? ' AND (is_rh = 0 OR is_rh IS NULL) ' : '';
	
	my $prestation_types = sql_select_all ("SELECT * FROM prestation_types WHERE fake = 0 AND id_organisation = ? AND IFNULL(no_stats, 0) = 0 $rh_filter ORDER BY label_short", $_USER -> {id_organisation});
	my @ids = map {$_ -> {id}} @$prestation_types;
	my $ids = join ',', (-1, @ids);
	
	my $from = $_REQUEST {year} . '-01-01';
	my $to   = $_REQUEST {year} . '-12-31';
	
	if ($_REQUEST {month} > 0) {
		$from = sprintf ('%04d-%02d-%02d', $_REQUEST {year}, $_REQUEST {month}, 1);
		$to   = sprintf ('%04d-%02d-%02d', $_REQUEST {year}, $_REQUEST {month}, Days_in_Month ($_REQUEST {year}, $_REQUEST {month}));
	}
	
	my $user_filter = '';
	
	if ($_REQUEST {id_user}) {
		$user_filter = " AND (prestations.id_user = $_REQUEST{id_user} OR prestations.id_users LIKE '%,$_REQUEST{id_user},%')";
	}
	elsif ($_REQUEST {id_site}) {
		my $ids_users = sql_select_ids ("SELECT id FROM users WHERE id_site = ?", $_REQUEST {id_site});
	
		$user_filter = " AND (prestations.id_user IN ($ids_users)";
	
		foreach my $id (split /\,/, $ids_users) {
			$id > 0 or next;
			$user_filter .= " OR prestations.id_users LIKE '%,$id,%'";
		}
	
		$user_filter .= ')';
	
	}

	my $prestations = sql_select_all (<<EOS, $from, $to);
		SELECT
			prestations.id_prestation_type
			, MONTH(prestations.dt_start) AS month
			, prestations.id_user
			, prestations.id_users
			, SUM(prestations.cnt) cnt
		FROM
			prestations
		WHERE
			prestations.fake = 0
			AND prestations.id_prestation_type IN ($ids)
			AND prestations.dt_start BETWEEN ? AND ?
			$user_filter
		GROUP BY
			1, 2, 3, 4
EOS

	my $filter =
		$_REQUEST {id_site} ? " AND id_site = $_REQUEST{id_site} " :
		'';
	
	my $users = sql_select_all (<<EOS, $_USER -> {id_organisation}, $to, $to, $from, $from);
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
	
	my ($ids, $idx) = ids ($users);	
	
	my $lines =
		$_REQUEST {month} ?	$users :
		[ map {{ id => $_, label => ucfirst $month_names [$_ - 1]}} (1 .. 12) ];
	
	my $id2line = {};	
	foreach (@$lines) {$id2line -> {$_ -> {id}} = $_};
	
	my $total = {label => 'Total', is_total => 1};
	
	foreach my $prestation (@$prestations) {
	
		my @id_users = ($prestation -> {id_user}, grep {$_ > 0} split /\,/, $prestation -> {id_users});
		
		foreach my $id_user (@id_users) {
		
			if ($_REQUEST {id_user}) {
				$id_user == $_REQUEST {id_user} or next;
			}
			else {
				$idx -> {$id_user} > 0 or next;
			}
				
			my $line =
				$_REQUEST {month} ? $id2line -> {$id_user} :
				$id2line -> {$prestation -> {month}};
		
			foreach ($line, $total) {
				$_ -> {by_type} -> {$prestation -> {id_prestation_type}} += $prestation -> {cnt};
				$_ -> {cnt} += $prestation -> {cnt};
			}		
		
		}
				
	}
	
	push @$lines, $total;

	return {
		lines => $lines,
		sites => $sites,
		prestations => $prestations,
		users => [grep {$_ -> {id}} @$users],
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

################################################################################

sub select_inscriptions_par_jour {

	my $sites = sql_select_vocabulary (sites => {filter => "id_organisation = $_USER->{id_organisation}"});
	
	my $menu = @$sites == 0 ? undef : [map {{
		label     => $_ -> {label},
		href      => {id_site => $_ -> {id}},
		is_active => $_REQUEST {id_site} == $_ -> {id},
	}} ({label => 'Tous sites'}, @$sites)];

	my $site_filter = $_REQUEST {id_site} ? " AND IFNULL(id_site, 0) IN ($_REQUEST{id_site}, 0) " : '';

	$_REQUEST {__meta_refresh} = $_USER -> {refresh_period} || 300;
	
	unless ($_REQUEST {year}) {	
		($_REQUEST {week}, $_REQUEST {year}) = Week_of_Year (Today ());	
	}
	
	my $users = sql_select_vocabulary ('users', {filter => "id_role = 2 AND id_organisation = $_USER->{id_organisation}"});
	my $prestation_types = sql_select_vocabulary ('prestation_types', {filter => "id_organisation = $_USER->{id_organisation}"}),
	
	my $id_prestation_types = -1;
	foreach (@$prestation_types) {	$id_prestation_types .= ",$$_{id}" }
	
	my $dt_from = sprintf ('%04d-%02d-%02d', reverse split /\//, $_REQUEST {dt_from});
	my $dt_to   = sprintf ('%04d-%02d-%02d', reverse split /\//, $_REQUEST {dt_to});
	
	($_REQUEST {_week}, $_REQUEST {_year}) = Week_of_Year (reverse split /\//, $_REQUEST {dt_from});	
	
	my $filter = $_REQUEST {id_user} ? "AND (id_user = $_REQUEST{id_user} OR id_users LIKE ',%$_REQUEST{id_user}%,')" : '';
	
	if ($_REQUEST {half_start}) {
		$filter .= " AND prestations.half_start = " . $_REQUEST {half_start};
	}

	if ($_REQUEST {id_prestation_type}) {
		$filter .= " AND prestations.id_prestation_type = " . $_REQUEST {id_prestation_type};
	}

	my $id_prestations = sql_select_ids (<<EOS, $dt_to, $dt_from);
		SELECT
			id
		FROM
			prestations
		WHERE
			fake = 0
			AND dt_start  <= ?
			AND dt_finish >= ?
			AND id_prestation_type IN ($id_prestation_types)
			$filter
EOS

	 my $inscriptions_par_conseiller = sql_select_all (<<EOS);
	 	SELECT
	 		inscriptions.*
	 		, prestations.dt_start
	 		, prestations.dt_finish
	 		, users.label AS user_label
	 		, prestation_types.label_short
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 	WHERE
	 		inscriptions.fake = 0
	 		AND prestations.id IN ($id_prestations)
	 		$site_filter
	 	ORDER BY
	 		inscriptions.nom
	 		, inscriptions.prenom
EOS

	return {
		inscriptions_par_conseiller => $inscriptions_par_conseiller,
		prev  => $prev,		
		next  => $next,		
		users => $users,
		prestation_types => $prestation_types,
		menu  => $menu,
	};

}

1;

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
	
	my $ids_groups = sql_select_ids ("SELECT id FROM groups WHERE id_organisation = ? AND fake = 0 AND IFNULL(is_hidden, 0) = 0", $_USER -> {id_organisation});
	$ids_groups .= ",$_USER->{id_group}" if $_USER -> {id_group} > 0;
	
	my $users = sql_select_vocabulary ('users', {filter => "id_group IN ($ids_groups)"});
	
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
	
	my %ids_ext_fields = (-1 => 1);

	sql_select_loop (<<EOS, sub {foreach (split /\,/, $i -> {ids_ext_fields}) {$ids_ext_fields {$_} ||= 1}});
	 	SELECT DISTINCT
	 		prestation_types.ids_ext_fields
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 	WHERE
	 		inscriptions.fake = 0
	 		AND prestations.id IN ($id_prestations)
	 		$site_filter
EOS
		
	my $ids_ext_fields = join ',', keys %ids_ext_fields;

	my $ext_fields = sql_select_all (<<EOS);
		SELECT
			ext_fields.*
		FROM
			ext_fields
		WHERE
			ext_fields.id IN ($ids_ext_fields)
		ORDER BY
			ext_fields.ord
EOS
		
	my $filter = '';
	my @params = ();	
		
	foreach my $field (@$ext_fields) {
		
		$field -> {name} = 'field_' . $field -> {id};
		
		$_REQUEST {$field -> {name}} or next;
		
		if ($field -> {id_field_type} != 3) {
			$filter .= " AND $field->{name} = ?";
			push @params, $_REQUEST {$field -> {name}};
               	}
		else {
			$filter .= " AND $field->{name} LIKE ?";
			push @params, '%' . $_REQUEST {$field -> {name}} . '%';
		}
		

	}
	
	my $ids_inscriptions_par_conseiller = sql_select_ids (<<EOS, @params);
		SELECT
			inscriptions.id
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 	WHERE
	 		inscriptions.fake = 0
	 		AND prestations.id IN ($id_prestations)
	 		$site_filter
	 		$filter
EOS

	$ids_inscriptions_par_conseiller = sql_select_ids ("SELECT id FROM inscriptions WHERE id IN ($ids_inscriptions_par_conseiller) AND IFNULL(parent, 0) NOT IN ($ids_inscriptions_par_conseiller)");	

	my $cnt = $ids_inscriptions_par_conseiller =~ y/,/,/;
	
	$_REQUEST {start} += 0;
	
	my $portion = $_REQUEST {xls} ? 100000 : 50;
	
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
	 		inscriptions.id IN ($ids_inscriptions_par_conseiller)
	 	ORDER BY
	 		inscriptions.nom
	 		, inscriptions.prenom
	 	LIMIT
	 		$_REQUEST{start}, $portion
EOS

		
	foreach my $field (@$ext_fields) {
		
		if ($field -> {id_field_type} == 1) {
		
			$field -> {type} = 'input_select';
			
			$field -> {empty} = '[Tout ' . lc $field -> {label} . ']';
			
			if ($field -> {id_voc}) {
				$field -> {values} = sql_select_vocabulary ('voc_' . $field -> {id_voc});
			}
			else {
				$field -> {values} = sql_select_vocabulary ('users', {filter => "id_organisation = $_USER->{id_organisation}"});
			}			
			
			my %v = map {$_ -> {id} => $_ -> {label}} @{$field -> {values}};
							
			foreach my $i (@$inscriptions_par_conseiller) {
				$i -> {$field -> {name}} = $v {$i -> {$field -> {name}}}
			}

		}			
		elsif ($field -> {id_field_type} == 4) {
			
			$field -> {type} = 'input_checkbox';

			foreach my $i (@$inscriptions_par_conseiller) {
				$i -> {$field -> {name}} = $i -> {$field -> {name}} ? 'Oui' : 'Non';
			}
			
		}
		else {
			$field -> {type} = 'input_text';
			$field -> {keep_params} = [];
		}
			
	}
	
	my ($ids, $idx) = ids ($inscriptions_par_conseiller);
	
#	$_REQUEST {__suicide} = 1;
		
	return {
		inscriptions_par_conseiller => $inscriptions_par_conseiller,
		cnt                         => $cnt,
		portion                     => $portion,
		prev                        => $prev,		
		next                        => $next,		
		users                       => $users,
		prestation_types            => $prestation_types,
		menu                        => $menu,
		ext_fields                  => $ext_fields,
	};

}

1;

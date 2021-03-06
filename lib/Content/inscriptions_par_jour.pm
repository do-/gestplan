################################################################################

sub select_inscriptions_par_jour {

	if ($_USER -> {id_site}) {
	
		$_USER -> {id_site_group} = sql_select_scalar ('SELECT id_site_group FROM sites WHERE id = ?', $_USER -> {id_site});
	
	}
	
	$_USER -> {id_site_group} += 0;

	my $sites = sql_select_vocabulary (sites => {
	
		filter => $_USER -> {id_site_group} ?
		
			"id_site_group = $_USER->{id_site_group}" :
			
			"id_organisation = $_USER->{id_organisation}"
	
	});
	
	my $menu = @$sites == 0 ? undef : [map {{
		label     => $_ -> {label},
		href      => {id_site => $_ -> {id}, aliens => ''},
		is_active => ($_REQUEST {id_site} == $_ -> {id} and !$_REQUEST {aliens}),
	}} ({label => $_USER -> {id_site_group} ? sql_select_scalar ('SELECT label FROM site_groups WHERE id = ?', $_USER -> {id_site_group}) : 'Tous sites'}, @$sites)];
	
		
	my $site_filter = '';

	if ($_REQUEST {id_site}) {
		
		$site_filter = " AND IFNULL(users.id_site, 0) IN ($_REQUEST{id_site}, 0) ";
		
	}
	elsif ($_REQUEST {aliens}) {
		
		$site_filter = " AND prestations.id_organisation <> $_USER->{id_organisation} ";

	}
	elsif ($_USER -> {id_site_group}) {
	
		my $ids = sql_select_ids ('SELECT id FROM sites WHERE fake = 0 AND id_site_group = ?', $_USER -> {id_site_group});

		$site_filter = " AND IFNULL(users.id_site, 0) IN ($ids, 0) ";
		
	}

	$_REQUEST {__meta_refresh} = $_USER -> {refresh_period} || 300;
	
	unless ($_REQUEST {year}) {	
		($_REQUEST {week}, $_REQUEST {year}) = Week_of_Year (Today ());	
	}
	
	my $filter = $_USER -> {role} eq 'admin' ? '' : ' AND IFNULL(is_hidden, 0) = 0';
	
	my $ids_groups = sql_select_ids ("SELECT id FROM groups WHERE id_organisation = ? AND fake = 0 $filter", $_USER -> {id_organisation});
	$ids_groups .= ",$_USER->{id_group}" if $_USER -> {id_group} > 0;
	
	my $dt_from = sprintf ('%04d-%02d-%02d', reverse split /\//, $_REQUEST {dt_from});
	my $dt_to   = sprintf ('%04d-%02d-%02d', reverse split /\//, $_REQUEST {dt_to});

	my $users = sql_select_vocabulary ('users', {filter => "
		id_group IN ($ids_groups)
		AND IFNULL(users.dt_start,  '1970-01-01') <= '$dt_to'
		AND IFNULL(users.dt_finish, '9999-99-99') >= '$dt_from'
	"});
	
	my $prestation_types = sql_select_vocabulary ('prestation_types', {filter => "id_organisation = $_USER->{id_organisation}"}),
	
	my $id_prestation_types = -1;
	foreach (@$prestation_types) {	$id_prestation_types .= ",$$_{id}" }
		
#	($_REQUEST {_week}, $_REQUEST {_year}) = Week_of_Year (reverse split /\//, $_REQUEST {dt_from});
	
	my $filter = $_REQUEST {id_user} ? "AND (id_user = $_REQUEST{id_user} OR id_users LIKE ',%$_REQUEST{id_user}%,')" : '';
	
	if ($_REQUEST {half_start}) {
		$filter .= " AND prestations.half_start = " . $_REQUEST {half_start};
	}

	if ($_REQUEST {id_prestation_type}) {
		$filter .= " AND prestations.id_prestation_type = " . $_REQUEST {id_prestation_type};
	}

	my ($id_users, $idx_users) = ids ($users);

	$id_prestations = -1;
	
	my $id_prestations_table = 'id_prestations_' . $$;
	
	sql_do ("DROP   TEMPORARY TABLE IF     EXISTS $id_prestations_table");
	sql_do ("CREATE TEMPORARY TABLE IF NOT EXISTS $id_prestations_table (id INT PRIMARY KEY)");

	my $collect = sub {

		my $is_visible = $idx_users -> {$i -> {id_user}} || ($i -> {id_organisation} != $_USER -> {id_organisation});

		if (!$is_visible && $i -> {id_users}) {
		
			foreach my $id_user (split /\,/, $i -> {id_users}) {
			
				$idx_users -> {$id_user} or next;
				
				$is_visible = 1;
				
				last;
			
			}
		
		}

		$is_visible or return;

		sql_do ("REPLACE INTO $id_prestations_table (id) VALUES (?) ", $i -> {id});
			
	};

	my $organisation = sql_select_hash (organisations => $_USER -> {id_organisation});
	my $ids_partners = $organisation -> {ids_partners} || '-1';
	my $ids_alien_types = -1;
	my $ids_alien_partnerships = -1;
	
	if ($ids_partners ne '-1') {

		push @$menu, {
			label     => 'Partenaires',
			href      => {id_site => '', aliens => 1},
			is_active => $_REQUEST {aliens},
		};

		$ids_partners = sql_select_ids (<<EOS, $_REQUEST {year}, $_REQUEST {week});
			SELECT
				week_status.id_organisation
			FROM
				week_status
			WHERE
				week_status.id_organisation IN ($$organisation{ids_partners})
				AND week_status.id_week_status_type = 2
				AND week_status.year = ?
				AND week_status.week = ?
EOS

		$ids_alien_types = sql_select_ids (<<EOS, '%,' . $organisation -> {id} . ',%');
			SELECT
				id
			FROM
				prestation_types
			WHERE
				id_organisation IN ($ids_partners)
				AND (
					is_open = 1
					OR (
						is_open = 2
						AND ids_partners LIKE ?
					)
				)
EOS
#$time = __log_profilinig ($time, '      2');

		$ids_alien_partnerships = sql_select_ids (<<EOS, '%,' . $organisation -> {id} . ',%');
			SELECT
				id
			FROM
				prestation_partnerships
			WHERE
				id_organisation IN ($ids_partners)
				AND (
					is_open = 1
					OR (
						is_open = 2
						AND ids_partners LIKE ?
					)
				)
EOS

	}
		
	sql_select_loop (<<EOS, $collect, $dt_to, $dt_from);
		SELECT
			*
		FROM
			prestations
		WHERE
			fake = 0
			AND dt_start  <= ?
			AND dt_finish >= ?
			AND (
				(id_prestation_type IN ($id_prestation_types))
				OR prestations.id_prestation_partnership IN ($ids_alien_partnerships)
				OR (
					prestations.id_prestation_partnership IS NULL
					AND prestations.id_prestation_type IN ($ids_alien_types)
				)				
			)
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
	 		INNER JOIN $id_prestations_table ON prestations.id = $id_prestations_table.id
	 	WHERE
	 		inscriptions.fake = 0
	 		$site_filter
EOS
		
	my $ids_ext_fields = join ',', keys %ids_ext_fields;

	my $filter = '';
	my @params = ();	
	my @ext_fields = ();
	my $join = '';
		
	if ($_REQUEST {q}) {
		$filter .= " AND CONCAT(IFNULL(inscriptions.nom, ''), ' ', IFNULL(inscriptions.prenom, '')) LIKE ? ";
		push @params, '%' . $_REQUEST {q} . '%';
	}

	my $collect = sub {
		
		my $field = $i;
		
		push @ext_fields, {type => 'break',	break_table => 1,} unless @ext_fields % 5;

		push @ext_fields, $i;
		
		$field -> {name} = 'field_' . $field -> {id};
		
		$_REQUEST {$field -> {name}} or return;
		
		$join .= " LEFT JOIN ext_field_values AS t_$field->{name} ON (t_$field->{name}.id_inscription = inscriptions.id AND t_$field->{name}.id_ext_field = $field->{id})";

		if ($field -> {id_field_type} == 8) {
			$filter .= " AND CONCAT(',', t_$field->{name}.value, ',') LIKE ?";
			push @params, "\%,$_REQUEST{$field->{name}},\%";
        }
		elsif ($field -> {id_field_type} !~ /^[35]$/) {
			$filter .= " AND t_$field->{name}.value = ?";
			push @params, $_REQUEST {$field -> {name}};
        }
		else {
			$filter .= " AND t_$field->{name}.value LIKE ?";
			push @params, '%' . $_REQUEST {$field -> {name}} . '%';
		}
				
	};

	sql_select_loop (<<EOS, $collect, $_USER -> {id_organisation});
		SELECT
			ext_fields.*
		FROM
			ext_fields
		WHERE
			ext_fields.id IN ($ids_ext_fields)
			AND ext_fields.id_organisation = ?
		ORDER BY
			ext_fields.ord
EOS

	my $id_inscriptions_table = 'id_inscriptions_' . $$;
	
	sql_do ("DROP   TEMPORARY TABLE IF     EXISTS $id_inscriptions_table");
	sql_do ("CREATE TEMPORARY TABLE IF NOT EXISTS $id_inscriptions_table (id INT PRIMARY KEY)");

#	my $ids_inscriptions_par_conseiller = sql_select_ids (<<EOS, @params);

	sql_do (<<EOS, $_USER -> {id_organisation}, @params);
		REPLACE INTO
			$id_inscriptions_table (id)
		SELECT
			inscriptions.id
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN users AS authors ON inscriptions.id_author = authors.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 		INNER JOIN $id_prestations_table ON prestations.id = $id_prestations_table.id
	 		$join
	 		LEFT  JOIN inscriptions children ON children.parent = inscriptions.id
	 	WHERE
	 		inscriptions.fake = 0
	 		AND children.id IS NULL
			AND authors.id_organisation = ?
	 		$site_filter
	 		$filter
EOS

	my $cnt = sql_select_scalar ("SELECT COUNT(*) FROM $id_inscriptions_table");
	
	$_REQUEST {start} += 0;
	
	my $portion = $_REQUEST {xls} ? 100000 : 50;
	
	my $inscriptions_par_conseiller = sql_select_all (<<EOS);
		SELECT
			inscriptions.*
	 		, prestations.dt_start
	 		, prestations.dt_finish
	 		, users.label AS user_label
	 		, prestation_types.label_short
	 		, reception.label AS recu_par
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 		LEFT  JOIN users AS reception ON inscriptions.id_user = reception.id
	 		INNER JOIN $id_inscriptions_table ON $id_inscriptions_table.id = inscriptions.id
#	 	WHERE
#	 		inscriptions.id IN ($ids_inscriptions_par_conseiller)
	 	ORDER BY
	 		inscriptions.nom
	 		, inscriptions.prenom
	 	LIMIT
	 		$_REQUEST{start}, $portion
EOS

	my ($ids, $idx) = ('', {});
		
	foreach my $i (@$inscriptions_par_conseiller) {
		
		$idx -> {$i -> {parent} || $i -> {id}} = $i;
		
	}

	$ids = join ',', (-1, keys %$idx);

	sql_select_loop ("SELECT * FROM ext_field_values WHERE id_inscription IN ($ids)", sub {
	
		$idx -> {$i -> {id_inscription}} -> {"field_$i->{id_ext_field}"} = $i -> {file_name} || $i -> {value};
	
	});
		
	foreach my $field (@ext_fields) {
		
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
		elsif ($field -> {id_field_type} == 8) {
		
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
			
				$i -> {$field -> {name}} =
				
					join ', ',
					
						sort grep {$_}
						
							@v {split /,/, $i -> {$field -> {name}}}

			}

		}
		elsif ($field -> {id_field_type} == 4) {
			
			$field -> {type} = 'input_checkbox';

			foreach my $i (@$inscriptions_par_conseiller) {
				defined $i -> {$field -> {name}} or next;
				$i -> {$field -> {name}} = $i -> {$field -> {name}} ? 'Oui' : 'Non';
			}
			
		}
		elsif ($field -> {id_field_type} == 7) {
			
			$field -> {type} = 'input_checkbox';

			foreach my $i (@$inscriptions_par_conseiller) {
				$i -> {$field -> {name}} = $i -> {$field -> {name}} ? 'Oui' : 'Non';
			}
			
		}
		elsif ($field -> {type} ne 'break') {
			$field -> {type} = 'input_text';
			$field -> {keep_params} = [];
		}
			
	}
		
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
		ext_fields                  => \@ext_fields,
	};

}

1;

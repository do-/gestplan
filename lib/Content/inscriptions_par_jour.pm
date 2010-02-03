################################################################################

sub select_inscriptions_par_jour {

#	exists $_REQUEST {id_site} or $_REQUEST {id_site} = 0;
#
#	my $organisation = sql (organisations => $_USER -> {id_organisation});
#	
#	$organisation -> {ids_partners} ||= -1;
#
#	my $sites = sql (sites => [
#		[id_organisation => $_USER->{id_organisation}],
#		[ORDER           => 'ord, label'],
#	]);
#	
#	if ($organisation -> {ids_partners} ne '-1') {
#	
#		if (@$sites == 0) {
#	
#			push @$sites, {
#				id    => 0,
#				label => $organisation -> {empty_site_label},
#			}
#		
#		}
#
#		push @$sites, {
#			id    => '',
#			label => $organisation -> {partners_site_label},
#		}
#	
#	}
#	
#	my $menu = @$sites == 0 ? undef : [map {{
#		label     => $_ -> {label},
#		href      => {id_site => $_ -> {id}},
#		is_active => $_REQUEST {id_site} == $_ -> {id},
#	}} ({label => 'Tous'}, @$sites)];



	my $sites = sql_select_vocabulary (sites => {filter => "id_organisation = $_USER->{id_organisation}", order => 'ord,label'});
	
	!@$sites or defined $_REQUEST {id_site} or $_REQUEST {id_site} = $_USER -> {id_site};

	my $organisation = sql_select_hash (organisations => $_USER -> {id_organisation});
	
	my @menu = ({
		label     => 'Tous',
		href      => {id_site => 0, aliens => '', __next_query_string => -1},
		is_active => !$_REQUEST {id_site} && !$_REQUEST {aliens},
		keep_esc  => 1,
	});
	
	foreach my $site (@$sites) {
	
		push @menu, {
			label     => $site -> {label},
			href      => {id_site => $site -> {id}, aliens => '', __next_query_string => -1},
			is_active => $_REQUEST {id_site} == $site -> {id} && !$_REQUEST {aliens},
			keep_esc  => 1,
		};
	
	}
	
	if (@menu == 1) {
		
		$menu [0] -> {label} = $organisation -> {empty_site_label},
		
	}

	if ($organisation -> {ids_partners} ne '-1') {
	
		push @menu, {
			label     => $organisation -> {partners_site_label},
			href      => {id_site => '', aliens => 1, __next_query_string => -1},
			is_active => $_REQUEST {aliens},
			keep_esc  => 1,
		};
	
	}
	
	
	
	

	
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

	my ($id_users, $idx_users) = ids ($users);
	
	my $prestation_types =
	
		$_REQUEST {aliens} ? sql (prestation_types => [['id_organisation IN '=> "$organisation->{ids_partners}" ]]) :

		sql (prestation_types => [[id_organisation => $_USER -> {id_organisation} ]]);

	my $id_prestation_types = ids ($prestation_types);
	
	my $filter = $_REQUEST {id_user} ? "AND (id_user = $_REQUEST{id_user} OR id_users LIKE ',%$_REQUEST{id_user}%,')" : '';
	
	if ($_REQUEST {half_start}) {
		$filter .= " AND prestations.half_start = " . $_REQUEST {half_start};
	}

	if ($_REQUEST {id_prestation_type}) {
		$filter .= " AND prestations.id_prestation_type = " . $_REQUEST {id_prestation_type};
	}

	if ($_REQUEST {id_site} > 0) {
		$filter .= " AND prestations.id_site = " . $_REQUEST {id_site};
	}
	

	my $collect = sub {

#		my $is_visible = $idx_users -> {$i -> {id_user}};
#
#		if (!$is_visible && $i -> {id_users}) {
#		
#			foreach my $id_user (split /\,/, $i -> {id_users}) {
#			
#				$idx_users -> {$id_user} or next;
#				
#				$is_visible = 1;
#				
#				last;
#			
#			}
#		
#		}
#		
#		$is_visible or return;
		
		$id_prestations .= ",$i->{id}";
	
	};
	
	unless ($_REQUEST {aliens}) {
		
		$filter .= " AND (1=1)";
	
	}

	my $id_prestations = sql_select_ids (<<EOS, $dt_to, $dt_from);
		SELECT
			*
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

	sql_select_loop (<<EOS, $collect);
		SELECT
			ext_fields.*
		FROM
			ext_fields
		WHERE
			ext_fields.id IN ($ids_ext_fields)
		ORDER BY
			ext_fields.ord
EOS

	my $ids_inscriptions_par_conseiller = sql_select_ids (<<EOS, @params);
		SELECT
			inscriptions.id
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 		$join
	 	WHERE
	 		inscriptions.fake = 0
	 		AND prestations.id IN ($id_prestations)
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
	 		, reception.label AS recu_par
	 		, sites.label AS site_label
	 	FROM
	 		inscriptions
	 		INNER JOIN prestations ON inscriptions.id_prestation = prestations.id
	 		INNER JOIN users ON prestations.id_user = users.id
	 		INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	 		LEFT  JOIN users AS reception ON inscriptions.id_user = reception.id
	 		LEFT  JOIN sites ON prestations.id_site = sites.id
	 	WHERE
	 		inscriptions.id IN ($ids_inscriptions_par_conseiller)
	 	ORDER BY
	 		inscriptions.nom
	 		, inscriptions.prenom
	 	LIMIT
	 		$_REQUEST{start}, $portion
EOS

	my ($ids, $idx) = ids ($inscriptions_par_conseiller);

	sql_select_loop ("SELECT * FROM ext_field_values WHERE id_inscription IN ($ids)", sub {
	
		$idx -> {$i -> {id_inscription}} -> {"field_$i->{id_ext_field}"} = $i -> {value};
	
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
		
	return_md5_checked {
		inscriptions_par_conseiller => $inscriptions_par_conseiller,
		cnt                         => $cnt,
		portion                     => $portion,
		prev                        => $prev,		
		next                        => $next,		
		users                       => $users,
		prestation_types            => $prestation_types,
		menu                        => \@menu,
		ext_fields                  => \@ext_fields,
	};

}

1;

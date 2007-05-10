################################################################################

sub do_clear_prestations {

	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my $from = sprintf ('%04d-%02d-%02d', @monday);
	my $to   = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, 4));
	
	my $ids  = sql_select_ids (<<EOS, $_USER -> {id_organisation} + 0, $to, $from);
		SELECT
			prestations.id
		FROM
			prestations
			INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
		WHERE
			1=1
			AND prestation_types.id_organisation = ?
			AND prestations.dt_start  <= ?
			AND prestations.dt_finish >= ?
EOS
	
	sql_do ("DELETE FROM prestations  WHERE id IN ($ids)");
	sql_do ("DELETE FROM inscriptions WHERE id_prestation IN ($ids)");
	
}

################################################################################

sub do_add_models_prestations {

	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my $prestation_models = sql_select_all (<<EOS, $_USER -> {id_organisation}, $_REQUEST {week} % 2, {fake => 'prestation_models'});
		SELECT
			prestation_models.*
		FROM
			prestation_models
			INNER JOIN users ON prestation_models.id_user = users.id
		WHERE
			users.id_organisation = ?
			AND prestation_models.is_odd = ?
EOS

	foreach my $prestation_model (@$prestation_models) {
	
		my $dt = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, $prestation_model -> {day_start} - 1));
		
		my $id = sql_do_insert ('prestations', {
			fake                => 0,
			dt_start            => $dt,
			half_start          => $prestation_model -> {half_start},
			dt_finish           => $dt,
			half_finish         => $prestation_model -> {half_finish},
			id_user             => $prestation_model -> {id_user},
			id_prestation_type  => $prestation_model -> {id_prestation_type},
			id_prestation_model => $prestation_model -> {id},
		});
		
		my $item = sql_select_hash ('prestations', $id);
				
		$item -> {type} = sql_select_hash ('prestation_types', $item -> {id_prestation_type});
		
		$item -> {type} -> {time_step} ||= 30;
		
			
			
			








		my ($h, $m) = ();
			
		if ($item -> {half_start} == 1) {
			
			if ($item -> {type} -> {half_1_h}) {
				$h = $item -> {type} -> {half_1_h};
				$m = $item -> {type} -> {half_1_m};
			}
			else {
				$h = 9;
				$m = 15;
			}
			
		}
		else {
		
			if ($item -> {type} -> {half_2_h}) {
				$h = $item -> {type} -> {half_2_h};
				$m = $item -> {type} -> {half_2_m};
			}
			else {
				$h = 13;
				$m = 45;
			}
			
		}	





			
			
			
			
		for (my $i = 0; $i < $item -> {type} -> {length}; $i++) {			
		
			my $label = $item -> {type} -> {is_half_hour} ? sprintf ('%2dh%02d', $h, $m) : ($i + 1) . '.';
			
			sql_do_insert ('inscriptions', {
				id_prestation => $id,
				label => $label,
				fake  => -1,
			});
			
			$m += $item -> {type} -> {time_step};
			
			if ($m >= 60) {
				$h ++;
				$m %= 60;
			}
		
		}
		
		for (my $i = 0; $i < $item -> {type} -> {length_ext}; $i++) {			
		
			my $label = '+' . ($i + 1) . '.';
			
			sql_do_insert ('inscriptions', {
				id_prestation => $id,
				label => $label,
				fake  => -1,
			});
		
		}
				
	}
	
}

################################################################################

sub do_switch_status_prestations {

	sql_do ('DELETE FROM week_status WHERE year = ? AND week = ? AND id_organisation = ?', $_REQUEST {year}, $_REQUEST {week}, $_USER -> {id_organisation});
	sql_do_insert ('week_status', {
		fake => 0,
		year => $_REQUEST {year},
		week => $_REQUEST {week},
		id_week_status_type => $_REQUEST {id_week_status_type},
		id_organisation => $_USER -> {id_organisation},
	});
	
}

################################################################################

sub do_delete_prestations {
	sql_do ('DELETE FROM inscriptions WHERE id_prestation = ?', $_REQUEST {id});
	sql_do ('DELETE FROM prestations_rooms WHERE id_prestation = ?', $_REQUEST {id});
	sql_do_delete ('prestations');
}

################################################################################

sub validate_create_prestations {

	if ($_REQUEST {id_user} > 0) {

		$_REQUEST {id} = sql_select_scalar (
			'SELECT id FROM prestations WHERE fake = 0 AND (id_user = ? OR id_users LIKE ?) AND CONCAT(dt_start,half_start) <= ? AND CONCAT(dt_finish,half_finish) >= ?',
			$_REQUEST {id_user},
			'%,' . $_REQUEST{id_user} . ',%',
			$_REQUEST {dt_start} . $_REQUEST {half_start},
			$_REQUEST {dt_start} . $_REQUEST {half_start},
		);	

	}
	else {

		$_REQUEST {id} = sql_select_scalar (<<EOS, -1 * $_REQUEST {id_user}, $_REQUEST {dt_start} . $_REQUEST {half_start}, $_REQUEST {dt_start} . $_REQUEST {half_start});
			SELECT
				prestations.id
			FROM
				prestations_rooms
				INNER JOIN prestations ON prestations_rooms.id_prestation = prestations.id
			WHERE
				prestations_rooms.id_room = ?
				AND prestations.fake = 0
				AND CONCAT(prestations_rooms.dt_start,prestations_rooms.half_start) <= ?
				AND CONCAT(prestations_rooms.dt_finish,prestations_rooms.half_finish) >= ?
EOS

	}
	
	if (!$_REQUEST {id} && $_REQUEST {id_prestation_type} && $_REQUEST {id_user} > 0) {
		
		my $prestation_type = sql_select_hash ('prestation_types', $_REQUEST {id_prestation_type});
		
		if ($prestation_type -> {id_day_period} < 3) {		
			if ($prestation_type -> {id_day_period} == 1 && $_REQUEST {half_start} == 2) { return "Les $$prestation_type{label_short} ne peuvent �tre affect�s que les matins"; };
			if ($prestation_type -> {id_day_period} == 2 && $_REQUEST {half_start} == 1) { return "Les $$prestation_type{label_short} ne peuvent �tre affect�s que les apr�s-midis"; };		
		}				
	
		my $user = sql_select_hash ('users', $_REQUEST {id_user});
			
		$prestation_type -> {ids_roles} =~ /\,$$user{id_role}\,/ or return "D�sol�, mais $$user{label} ne peut pas assister aux prestations $$prestation_type{label_short}.";		

		foreach my $id_room (grep {$_ > 0} split /\,/, $prestation_type -> {ids_rooms}) {
		
			my $room = sql_select_hash ('rooms', $id_room);

			0 == sql_select_scalar (<<EOS, $id_room, $_REQUEST {dt_finish} . $_REQUEST {half_finish}, $_REQUEST {dt_start} . $_REQUEST {half_start}) or return "D�sol�, mais la $$room{label} est occup�e pendant cette p�riode.";
				SELECT
					prestations_rooms.id
				FROM
					prestations_rooms
					INNER JOIN prestations ON prestations_rooms.id_prestation = prestations.id
				WHERE
					prestations_rooms.id_room = ?
					AND prestations_rooms.fake = 0
					AND CONCAT(prestations_rooms.dt_start,  prestations_rooms.half_start)  <= ?
					AND CONCAT(prestations_rooms.dt_finish, prestations_rooms.half_finish) >= ?
				LIMIT
					1
EOS
				
		}
	
	}

	return undef;
	
}

################################################################################

sub do_create_prestations {
		
	unless ($_REQUEST {id}) {
	
		$_REQUEST {id} = sql_do_insert ('prestations', {
			id_user => $_REQUEST {id_user},
			dt_start => $_REQUEST {dt_start},
			half_start => $_REQUEST {half_start},
			dt_finish => $_REQUEST {dt_finish},
			half_finish => $_REQUEST {half_finish},
			id_prestation_type => $_REQUEST {id_prestation_type},
		});
		
		my $prestation_type = sql_select_hash ('prestation_types', $_REQUEST {id_prestation_type});
		
		foreach my $id_room (grep {$_ > 0} split /\,/, $prestation_type -> {ids_rooms}) {
			sql_do_insert ('prestations_rooms', {
				dt_start => $_REQUEST {dt_start},
				half_start => $_REQUEST {half_start},
				dt_finish => $_REQUEST {dt_finish},
				half_finish => $_REQUEST {half_finish},
				id_prestation => $_REQUEST {id},
				id_room => $id_room,
			});
		}
		
		if (
			    $prestation_type -> {id}
			&& !$prestation_type -> {is_multiday}
			&& !$prestation_type -> {is_to_edit}
			&&  $prestation_type -> {id_people_number} < 3
		) {
		
			sql_do ('UPDATE prestations SET id_prestation_type = 0 WHERE id = ?', $_REQUEST {id});
			
			$_REQUEST {_id_user} =            $_REQUEST {id_user};
			$_REQUEST {_dt_start} =           $_REQUEST {dt_start};
			$_REQUEST {_half_start} =         $_REQUEST {half_start};
			$_REQUEST {_dt_finish} =          $_REQUEST {dt_finish};
			$_REQUEST {_half_finish} =        $_REQUEST {half_finish};
			$_REQUEST {_id_prestation_type} = $_REQUEST {id_prestation_type};
			
			do_update_prestations ();
			
			esc ();		
		}
	
	}	
		
}

################################################################################

sub do_update_prestations {

	my $old_item = sql_select_hash ('prestations');

	sql_do_update ('prestations', [qw(
		dt_start
		half_start
		dt_finish
		half_finish
		id_user
		id_users
		id_prestation_type
		note
	)]);
		
	my $item = sql_select_hash ('prestations');

	sql_do ('UPDATE prestations_rooms SET fake = 0, dt_start = ?, half_start = ?, dt_finish = ?, half_finish = ? WHERE id_prestation = ?'
		, $_REQUEST {_dt_start}
		, $_REQUEST {_half_start}
		, $_REQUEST {_dt_finish}
		, $_REQUEST {_half_finish}
		, $item -> {id}
	);
	
	if (
		$old_item -> {id_prestation_type} != $item -> {id_prestation_type} ||
		0 == sql_select_scalar ('SELECT COUNT(*) FROM inscriptions WHERE id_prestation = ?', $_REQUEST {id})
	) {
	
		sql_do ('DELETE FROM inscriptions WHERE id_prestation = ?', $item -> {id});
		
		$item -> {type} = sql_select_hash ('prestation_types', $item -> {id_prestation_type});
		
		$item -> {type} -> {time_step} ||= 30;
			
			
			
			
			
			
			
			
			
			
			
			
			
		my ($h, $m) = ();
			
		if ($item -> {half_start} == 1) {
			
			if ($item -> {type} -> {half_1_h}) {
				$h = $item -> {type} -> {half_1_h};
				$m = $item -> {type} -> {half_1_m};
			}
			else {
				$h = 9;
				$m = 15;
			}
			
		}
		else {
		
			if ($item -> {type} -> {half_2_h}) {
				$h = $item -> {type} -> {half_2_h};
				$m = $item -> {type} -> {half_2_m};
			}
			else {
				$h = 13;
				$m = 45;
			}
			
		}	
			
			
			
			
			
			
			
			
			
			
		for (my $i = 0; $i < $item -> {type} -> {length}; $i++) {			
		
			my $label = $item -> {type} -> {is_half_hour} ? sprintf ('%2dh%02d', $h, $m) : ($i + 1) . '.';
			
			sql_do_insert ('inscriptions', {
				id_prestation => $_REQUEST {id},
				label => $label,
				fake  => -1,
			});
			
			$m += $item -> {type} -> {time_step};
			
			if ($m >= 60) {
				$h ++;
				$m %= 60;
			}
		
		}
		
		for (my $i = 0; $i < $item -> {type} -> {length_ext}; $i++) {			
		
			my $label = '+' . ($i + 1) . '.';
			
			sql_do_insert ('inscriptions', {
				id_prestation => $_REQUEST {id},
				label => $label,
				fake  => -1,
			});
		
		}

	}	

}

################################################################################

sub validate_update_prestations {
	
	$_REQUEST {_id_prestation_type} or return "#_id_prestation_type#:Veuillez choisir le type de prestation";
	
	my $prestation_type = sql_select_hash ('prestation_types', $_REQUEST {_id_prestation_type});
	
	unless ($prestation_type -> {is_multiday}) {
		$_REQUEST {_dt_start}   eq $_REQUEST {_dt_finish} or return "#_id_prestation_type#:Ce type de prestation ne peut pas durer plusieurs jours";
		$_REQUEST {_half_start} == $_REQUEST {_half_finish} or return "#_id_prestation_type#:Ce type de prestation ne peut pas durer plusieurs demi-jours";
	}
	
	if ($prestation_type -> {id_day_period} == 1) {
		$_REQUEST {_half_start} == 1 or return "#_half_start#:Ce type de prestation ne peut pas commencer l'apr�s-midi";
	}

	if ($prestation_type -> {id_day_period} == 2) {
		$_REQUEST {_half_start} == 2 or return "#_half_start#:Ce type de prestation ne peut pas commencer le matin";
	}
	
	my @start  = vld_date ('dt_start');
	my @finish = vld_date ('dt_finish');
			
	if (Delta_Days (@start, @finish) < 0) {
		return "#_dt_finish#: L'ordre des dates est incorrect";
	}
	elsif (Delta_Days (@start, @finish) < 0 && $_REQUEST {_half_start} > $_REQUEST {_half_finish}) {
		return "#_half_finish#: L'ordre des p�riodes est incorrect";
	}
	
	my @id_users = grep {$_ != $_REQUEST {_id_user}} get_ids ('id_users');
	$_REQUEST {_id_users} ||= join ',', (-1, @id_users, -1);
		
	foreach my $id_user ($_REQUEST {_id_user}, @id_users) {

		my $user = sql_select_hash ('users', $id_user);
		
		$prestation_type -> {ids_roles} =~ /\,$$user{id_role}\,/ or return "D�sol�, mais $$user{label} ne peut pas assister aux prestations $$prestation_type{label_short}.";
			
		0 == sql_select_scalar (<<EOS, $_REQUEST {id}, $user -> {id}, '%,' . $user -> {id} . ',%' , $_REQUEST {_dt_finish} . $_REQUEST {_half_finish}, $_REQUEST {_dt_start} . $_REQUEST {_half_start}) or return "D�sol�, mais $$user{label} est occup� pendant cette p�riode.";
			SELECT
				id
			FROM
				prestations
			WHERE
				id <> ?
				AND (id_user = ? OR id_users LIKE ?)
				AND fake = 0
				AND CONCAT(dt_start,  half_start)  <= ?
				AND CONCAT(dt_finish, half_finish) >= ?
			LIMIT
				1
EOS

	}

	return undef;
	
}

################################################################################

sub get_item_of_prestations {

	my $item = sql_select_hash ('prestations');

	Dumper ($item);
	
	$item -> {id_users} = [split /\,/, $item -> {id_users}];

    	$item -> {id_prestation_type} += 0;
    	
	$item -> {prestation_type} = sql_select_hash ('prestation_types', $item -> {id_prestation_type});

	$item -> {ids_rooms} = [grep {$_ > 0} split /\,/, $item -> {prestation_type} -> {ids_rooms}];
	
	$item -> {_dt_start}  = $item -> {dt_start};
	$item -> {_dt_finish} = $item -> {dt_finish};
	
	__d ($item, 'dt_start', 'dt_finish');

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	my $filter = '1=1';
	
	if ($_USER -> {role} ne 'admin') {
		
		if ($item -> {id_user} == $_USER -> {id}) {
		
			$filter = <<EOS;
					is_placeable_by_conseiller = 1
					OR ids_users LIKE '%,$$_USER{id},%'
					OR id=$$item{id_prestation_type}
EOS
			
		}
		else {

			$filter = <<EOS;
					ids_users LIKE '%,$$_USER{id},%'
					OR id=$$item{id_prestation_type}
EOS

		}
	
	}
	
	$filter = "($filter) AND id_organisation = $_USER->{id_organisation}";
	
	add_vocabularies ($item,
		'users'            => {filter => "id_organisation = $_USER->{id_organisation} AND id_group > 0 AND (dt_finish IS NULL OR dt_finish > '$item->{_dt_finish}')"},
		'prestation_types' => {filter => $filter},
	);

	$item -> {day_periods} = [
		{id => 1, label => 'matin'},
		{id => 2, label => 'apr�s-midi'},
	];

	$item -> {path} = [
		{type => 'prestations', name => 'Prestations'},
		{type => 'prestations', name => $item -> {label}, id => $item -> {id}},
	];
	
	$item -> {inscriptions} = sql_select_all ('SELECT * FROM inscriptions WHERE id_prestation = ? ORDER BY id', $item -> {id}, {fake => 'inscriptions'});

	$item -> {prestations_rooms} = sql_select_all (<<EOS, $item -> {id});
		SELECT
			prestations_rooms.*
			, rooms.label
			, period_start.label  AS start_label
			, period_finish.label AS finish_label
		FROM
			prestations_rooms
			INNER JOIN rooms ON prestations_rooms.id_room = rooms.id
			INNER JOIN day_periods AS period_start  ON prestations_rooms.half_start  = period_start.id
			INNER JOIN day_periods AS period_finish ON prestations_rooms.half_finish = period_finish.id
		WHERE
			prestations_rooms.id_prestation = ?
		ORDER BY
			rooms.label
			, prestations_rooms.dt_start
			, prestations_rooms.half_start
EOS
	
	return $item;
	
}

################################################################################

sub select_prestations {

	my $sites = sql_select_vocabulary (sites => {filter => "id_organisation = $_USER->{id_organisation}"});
	
	my $menu = @$sites == 0 ? undef : [map {{
		label     => $_ -> {label},
		href      => {id_site => $_ -> {id}},
		is_active => $_REQUEST {id_site} == $_ -> {id},
	}} ({label => 'Tous sites'}, @$sites)];

	my $site_filter = $_REQUEST {id_site} ? " AND IFNULL(id_site, 0) IN ($_REQUEST{id_site}, 0) " : '';

	$_REQUEST {__meta_refresh} = $_USER -> {refresh_period} || 300;
	
	my $default_color = sql_select_scalar ('SELECT color FROM prestation_type_groups WHERE id = -1');
	my $busy_color    = sql_select_scalar ('SELECT color FROM prestation_type_groups WHERE id = -2');

	$_REQUEST {week} = 1 if $_REQUEST {week} eq '0';
	
	unless ($_REQUEST {year}) {	
		($_REQUEST {week}, $_REQUEST {year}) = Week_of_Year (Today ());	
	}
	
	if ($_REQUEST {week} > 52) {
		$_REQUEST {year} ++;
		$_REQUEST {week} %= 52;
	}	

	my @day = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my $prev = [Week_of_Year (Add_Delta_Days (@day, -7))];
	my $next = [Week_of_Year (Add_Delta_Days (@day, 7))];
	
	my @days = ();
	
	my $ix_days = {};
	
	for (my $i = 0; $i < 5; $i++) {
	
		my $iso_dt = sprintf ('%04d-%02d-%02d', @day);
		my $fr_dt  = sprintf ('%02d/%02d/%04d', reverse @day);
	
		my $label = $day_names [$i] . '&nbsp;' . $day [2];
		
		my $h_create = {href => "/?type=prestations&action=create&dt_start=$iso_dt&half_start=1&dt_finish=$iso_dt&half_finish=1&id_prestation_type=$_REQUEST{id_prestation_type}"};
		check_href ($h_create);
		
		push @days, {
			id => 2 * ($i + 1),
			iso_dt => $iso_dt,
			fr_dt => $fr_dt,
			label => $label,
			date  => [@day],
			create_href => $h_create -> {href},
		};
		
		$ix_days -> {$iso_dt . '-' . 1} = $days [-1];
		
		if (@days > 1) {
			$days [-2] -> {next} = $days [-1];
		}

		my $h_create = {href => "/?type=prestations&action=create&dt_start=$iso_dt&half_start=2&dt_finish=$iso_dt&half_finish=2&id_prestation_type=$_REQUEST{id_prestation_type}"};
		check_href ($h_create);

		push @days, {
			id => 2 * ($i + 1) + 1,
			iso_dt => $iso_dt,
			fr_dt => $fr_dt,
			label => $label,
			date  => [@day],
			create_href => $h_create -> {href},
		};
				
		$ix_days -> {$iso_dt . '-' . 2} = $days [-1];

		$days [-2] -> {next} = $days [-1];

		@day = Add_Delta_Days (@day, 1);
	
	}
	
	my $week_status_type = sql_select_hash ('week_status_types', week_status ($days [0] -> {fr_dt}));
	
	if (is_past ($days [0] -> {fr_dt})) {		
		$week_status_type -> {switch} = $week_status_type -> {id} == 3 ?
			{id => 2, icon => 'tv_0', label => 'R�activer'} :
			{id => 3, icon => 'tv_1', label => 'Clo�trer'}  ;					
	}
	else {
		$week_status_type -> {switch} = $week_status_type -> {id} == 1 ?
			{id => 2, icon => 'tv_0', label => 'Publier'}   :
			{id => 1, icon => 'tv_1', label => 'Cacher'}    ;
	}


	my $dt_start  = $days [0]  -> {iso_dt};
	my $dt_finish = $days [-1] -> {iso_dt};


	my $organisation = sql_select_hash ('organisations', $_USER -> {id_organisation});
	$organisation -> {ids_partners} ||= '-1';

	my $alien_prestations = sql_select_all (<<EOS);
			SELECT
				prestations.id
				, prestations.id_user
				, prestations.id_users
				, prestations.note
				, prestation_types.label_short AS label
				, prestation_types.is_half_hour
				, prestation_types.is_placeable_by_conseiller
				, prestation_types.ids_users
				, IF(prestations.dt_start < '$dt_start', '$dt_start', prestations.dt_start) AS dt_start
				, IF(prestations.dt_start < '$dt_start', 1, prestations.half_start) AS half_start
				, IF(prestations.dt_finish > '$dt_finish', '$dt_finish', prestations.dt_finish) AS dt_finish
				, IF(prestations.dt_finish > '$dt_finish', 2, prestations.half_finish) AS half_finish
				, IFNULL(prestation_type_group_colors.color, prestation_type_groups.color) AS color
				, 1 AS is_alien
			FROM
				prestations
				LEFT  JOIN prestation_types       ON prestations.id_prestation_type = prestation_types.id
				LEFT  JOIN prestation_type_groups ON prestation_types.id_prestation_type_group = prestation_type_groups.id
				LEFT  JOIN prestation_type_group_colors ON (
					prestation_type_group_colors.id_prestation_type_group = prestation_type_groups.id
					AND prestation_type_group_colors.id_organisation = ?
				)
			WHERE
				prestations.fake = 0
				AND prestations.dt_start  <= '$dt_finish'
				AND prestations.dt_finish >= '$dt_start'
				AND prestation_types.is_open = 1
				AND prestation_types.id_organisation IN ($$organisation{ids_partners})
EOS

	my @alien_id_users = (-1);	
	foreach my $alien_prestation (@$alien_prestations) {	
		push @alien_id_users, $alien_prestation -> {id_user};
		push @alien_id_users, (split /\,/, $alien_prestation -> {id_users});	
	}
	my $alien_id_users = join ',', @alien_id_users;	

	my $users = sql_select_all (<<EOS, $days [-1] -> {iso_dt}, $days [0] -> {iso_dt}, $_USER -> {id_organisation});
		SELECT
			users.id
			, IFNULL(prenom, users.label) AS label
			, dt_start - INTERVAL 1 DAY  AS dt_start
			, dt_finish + INTERVAL 1 DAY AS dt_finish
			, roles.id AS id_role
			, IF(users.id_organisation = $$_USER{id_organisation}, roles.label, CONCAT('Partenaire : ', organisations.label)) AS role
			, IF(users.id_organisation = $$_USER{id_organisation}, 0, 1) AS is_alien
		FROM
			users
			INNER JOIN groups AS roles ON users.id_group = roles.id
			INNER JOIN organisations ON users.id_organisation = organisations.id
		WHERE
			users.fake = 0
#			AND users.id_role IN (2,3)
			$site_filter
			AND (dt_start  IS NULL OR dt_start  <= ?)
			AND (dt_finish IS NULL OR dt_finish >= ?)
			AND (users.id_organisation = ? OR (users.id IN ($alien_id_users) AND users.id_role < 3))
		ORDER BY
			IF(users.id_organisation = $$_USER{id_organisation}, 0, 1)
			, roles.ord
			, prenom
EOS

	my @users = ();
	my $last_role = '';
	
	foreach my $user (@$users) {
	
		my $role = $user -> {role};
		
		unless ($user -> {is_alien}) {
			$role =~ s{^(\S+)}{$1s};
		}
		
		$last_role eq $role or push @users, {id => 0, label => $role};
		push @users, $user;
		$last_role = $role;
		
	}
	
	push @users, {label => 'Salles'};
	push @users, @{ sql_select_all ("SELECT -id AS id, label FROM rooms WHERE fake = 0 $site_filter AND id_organisation = ? ORDER BY label", $_USER -> {id_organisation})};
	
	$users = \@users;	

	my $prestations = [];
	my $prestations_rooms = [];
		
	if ($week_status_type -> {id} != 1 || $_USER -> {role} eq 'admin') {
	
		$prestations = [@$alien_prestations, @{sql_select_all (<<EOS, 0 + $_USER -> {id_organisation}, $_USER -> {id_organisation})}];
			SELECT
				prestations.id
				, prestations.id_user
				, prestations.id_users
				, prestations.note
				, prestations.id_prestation_model
				, prestation_types.label_short AS label
				, prestation_types.is_half_hour
				, prestation_types.is_placeable_by_conseiller
				, prestation_types.ids_users
				, IF(prestations.dt_start < '$dt_start', '$dt_start', prestations.dt_start) AS dt_start
				, IF(prestations.dt_start < '$dt_start', 1, prestations.half_start) AS half_start
				, IF(prestations.dt_finish > '$dt_finish', '$dt_finish', prestations.dt_finish) AS dt_finish
				, IF(prestations.dt_finish > '$dt_finish', 2, prestations.half_finish) AS half_finish
				, IFNULL(prestation_type_group_colors.color, prestation_type_groups.color) AS color
			FROM
				prestations
				INNER JOIN users ON prestations.id_user = users.id
				INNER JOIN prestation_types       ON prestations.id_prestation_type = prestation_types.id
				LEFT  JOIN prestation_type_groups ON prestation_types.id_prestation_type_group = prestation_type_groups.id
				LEFT  JOIN prestation_type_group_colors ON (
					prestation_type_group_colors.id_prestation_type_group = prestation_type_groups.id
					AND prestation_type_group_colors.id_organisation = ?
				)
			WHERE
				prestations.fake = 0
#				AND users.id_role IN (2,3)
				AND prestations.dt_start  <= '$dt_finish'
				AND prestations.dt_finish >= '$dt_start'
				AND users.id_organisation = ?
EOS
		
		$prestations_rooms = sql_select_all (<<EOS, $_USER -> {id_organisation});
			SELECT
				prestations.id
				, - prestations_rooms.id_room AS id_user
				, prestation_types.label_short AS label
				, prestation_types.is_half_hour
				, prestation_types.is_placeable_by_conseiller
				, prestation_types.ids_users
				, IF(prestations_rooms.dt_start  < '$dt_start',  '$dt_start', prestations_rooms.dt_start) AS dt_start
				, IF(prestations_rooms.dt_start  < '$dt_start',  1, prestations_rooms.half_start) AS half_start
				, IF(prestations_rooms.dt_finish > '$dt_finish', '$dt_finish', prestations_rooms.dt_finish) AS dt_finish
				, IF(prestations_rooms.dt_finish > '$dt_finish', 2, prestations_rooms.half_finish) AS half_finish
				, prestation_type_groups.color
			FROM
				prestations_rooms
				INNER JOIN prestations            ON prestations_rooms.id_prestation = prestations.id
				INNER JOIN prestation_types       ON prestations.id_prestation_type = prestation_types.id
				LEFT  JOIN prestation_type_groups ON prestation_types.id_prestation_type_group = prestation_type_groups.id
			WHERE
				prestations_rooms.fake = 0
				AND prestations_rooms.dt_start  <= '$dt_finish'
				AND prestations_rooms.dt_finish >= '$dt_start'
				AND prestation_types.id_organisation = ?
EOS
	
	}
	
	my $have_models = 0;

	foreach my $prestation (@$prestations, @$prestations_rooms) {
			
		if ($prestation -> {id_user} > 0) {
			
			sql_select_loop (
			
				'SELECT * FROM inscriptions WHERE id_prestation = ? AND fake = 0 ORDER BY id',
				
				sub {
					$prestation -> {inscriptions} .= ', ' if $prestation -> {inscriptions};
					$prestation -> {inscriptions} .= $i -> {prenom};
					$prestation -> {inscriptions} .= ' ';
					$prestation -> {inscriptions} .= $i -> {nom};
				},
				
				$prestation -> {id},
				
			);
			
		}
	
		$have_models ||= $prestation -> {id_prestation_model};
	
		my @id_users = grep {$_ > 0} split /\,/, $prestation -> {id_users};
		push @id_users, $prestation -> {id_user};
		
		if ($prestation -> {is_half_hour} != -1) {

			($prestation -> {cnt_inscriptions_total}, $prestation -> {cnt_inscriptions}) = sql_select_array ("SELECT SUM(1), SUM(IF(fake = 0, 1, 0)) FROM inscriptions WHERE id_prestation = ? AND label NOT LIKE '+%'", $prestation -> {id});

			if ($prestation -> {cnt_inscriptions_total} && $prestation -> {cnt_inscriptions_total} <= $prestation -> {cnt_inscriptions}) {
				$prestation -> {color} = $busy_color;
			}		
			elsif ($prestation -> {is_half_hour}) {
				$bgcolor = sql_select_scalar ('SELECT COUNT(*) FROM inscriptions WHERE fake <> 0 AND id_prestation = ?', $prestation -> {id}) ? '#ddffdd' : '#ffdddd',
			}

		}		

		$prestation -> {color} ||= $default_color;
		
		my $bgcolor = '#ffffd0';
						
		my $day = $ix_days -> {$prestation -> {dt_start} . '-' . $prestation -> {half_start}};

		my $rowspan =
			2 * Delta_Days ((split /-/, $prestation -> {dt_start}), (split /-/, $prestation -> {dt_finish}))
			+ $prestation -> {half_finish}
			- $prestation -> {half_start}
			+ 1			
			;

		foreach my $id_user (@id_users) {
			
			$day -> {by_user} -> {$id_user} ||= {
				id                            => $prestation -> {id},
				label                         => $prestation -> {label},
				bgcolor                       => $prestation -> {color},
				is_placeable_by_conseiller    => $prestation -> {is_placeable_by_conseiller},
				ids_users                     => $prestation -> {ids_users},
				cnt_inscriptions              => $prestation -> {cnt_inscriptions},
				cnt_inscriptions_total        => $prestation -> {cnt_inscriptions_total},
				note                          => $prestation -> {note},
				half_start                    => $prestation -> {half_start},
				inscriptions                  => $prestation -> {inscriptions},
			};				
			
			if ($rowspan > 1) {
			
				$day -> {by_user} -> {$id_user} -> {rowspan} = $rowspan;

				my $c_day = $day;

				for (my $i = 0; $i < $rowspan - 1; $i++) {
					$c_day = $c_day -> {next};
					$c_day -> {by_user} -> {$id_user} = {is_hidden => 1};
				}
				
			}
			
			if (
				$prestation -> {is_half_hour} == -1
				&& $id_user == $_USER -> {id}
				&& sql_select_scalar ('SELECT id FROM inscriptions WHERE id_prestation = ? AND is_unseen = 1 LIMIT 1', $prestation -> {id})
			) {
				
				$day -> {by_user} -> {$id_user} -> {status} = {icon => 100};
#				$day -> {by_user} -> {$id_user} -> {label}  .= ' !!!';
				
			}
		
		}	
		
	}
	
	my $off_periods = sql_select_all (<<EOS, $_USER -> {id_organisation});
		SELECT
			off_periods.id
			, off_periods.id_user
			, IF(off_periods.dt_start  < '$dt_start',  '$dt_start',  off_periods.dt_start)    AS dt_start
			, IF(off_periods.dt_start  < '$dt_start',  1,            off_periods.half_start)  AS half_start
			, IF(off_periods.dt_finish > '$dt_finish', '$dt_finish', off_periods.dt_finish)   AS dt_finish
			, IF(off_periods.dt_finish > '$dt_finish', 2,            off_periods.half_finish) AS half_finish
		FROM
			off_periods
			INNER JOIN users ON off_periods.id_user = users.id
		WHERE
			off_periods.fake = 0
			AND off_periods.dt_start  <= '$dt_finish'
			AND off_periods.dt_finish >= '$dt_start'
			AND users.id_organisation = ?
			$site_filter
EOS

	foreach my $user (@$users) {
	
		if ($user -> {dt_start} && $user -> {dt_start} ge $days [0] -> {iso_dt}) {
		
			push @$off_periods, {
				id => -1,
				id_user => $user -> {id},
				dt_start => $days [0] -> {iso_dt},
				dt_finish => $user -> {dt_start},
				half_start => 1,
				half_finish => 2,
			};

		}

		if ($user -> {dt_finish} && $user -> {dt_finish} le $days [-1] -> {iso_dt}) {
		
			push @$off_periods, {
				id => -1,
				id_user => $user -> {id},
				dt_start => $user -> {dt_finish},
				dt_finish => $days [-1] -> {iso_dt},
				half_start => 1,
				half_finish => 2,
			};
			
		}
		
	}

	if (@$off_periods) {
	
		my $user2ord = {};	
	    for (my $i = 0; $i < @$users; $i++) { $user2ord -> {$users -> [$i] -> {id}} = $i };

		my $day2ord = {};	
	    for (my $i = 0; $i < @days; $i++) { $day2ord -> {$days [$i] -> {iso_dt}} = $i };
	
	    	foreach my $off_period (@$off_periods) {

			my $span = 0;
	
			for (my $i = 0; $i < @days; $i++) {
				$days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {rowspan} ||= 1;
				$span += ($days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {rowspan} - 1);
				next if $days [$i] -> {iso_dt} lt $off_period -> {dt_start};
				$off_period -> {col_start} =
					$i
					+ $off_period -> {half_start}
					- $span
					;
				last;
			};
	
			for (my $i = @days - 1; $i >= 0; $i--) {
				next if $days [$i] -> {iso_dt} gt $off_period -> {dt_finish};		
				next if $days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {is_hidden};
				$off_period -> {col_finish} = $i + $off_period -> {half_finish} - 1;
				last;
			};
	
			for (my $i = @days - 1; $i >= 0; $i--) {
				next if $days [$i] -> {iso_dt} gt $off_period -> {dt_finish};		
				next if $days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {is_hidden};
				next if $days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {rowspan} <= 1;
				$off_period -> {col_finish} -= $days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {rowspan};
				$off_period -> {col_finish} ++;
			};

			$off_period -> {row}        = 0 + $user2ord -> {$off_period -> {id_user}};
			
		};
	
	}

	
	if ($_USER -> {role} eq 'admin') {
	
		$_USER -> {can_dblclick_others_empty} = 1;
	
	}
	else {

		$_USER -> {cnt_prestation_types} = sql_select_scalar ('SELECT COUNT(*) FROM prestation_types WHERE fake = 0 AND ids_users LIKE ?', '%,' . $_USER -> {id} . ',%');
		
		$_USER -> {can_dblclick_others_empty} = $_USER -> {cnt_prestation_types} > 0;
		
		if ($_REQUEST {id_prestation_type}) {
		
			my $prestation_type = sql_select_hash ('prestation_types', $_REQUEST {id_prestation_type});
	
			$_USER -> {can_dblclick_others_empty} &&= $prestation_type -> {ids_users} =~ /\,$_USER->{id}\,/
		
		}
	
	}
		
	return {
	
		week_status_type => $week_status_type,
	
		days => \@days,
		
		prev => $prev,
		
		next => $next,
		
		users => $users,
		
		off_periods => $off_periods,
		
		prestation_types => sql_select_vocabulary (
			prestation_types => {filter => 'id_organisation=' . $_USER -> {id_organisation} . ' AND ' . ($_USER -> {role} ne 'conseiller' ? '1=1' : "is_placeable_by_conseiller = 1 OR ids_users LIKE '%,$$_USER{id},%'")},
		),

		day_periods => sql_select_vocabulary ('day_periods', {order => 'id'}),
		
		have_models => $have_models,

		menu => $menu,		
			
	};
	
}

1;

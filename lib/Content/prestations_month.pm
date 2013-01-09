
################################################################################

sub select_prestations_month {

	my $item = {};

	$item -> {inscription_to_clone} = sql_select_hash (<<EOS => $_REQUEST {id_inscription_to_clone}) if $_REQUEST {id_inscription_to_clone};
		SELECT
			inscriptions.*
			, prestations.id_prestation_type
		FROM
			inscriptions
			LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
		WHERE
			inscriptions.id = ?
EOS

	$item -> {prestation_to_clone} = sql (prestations => $_REQUEST {id_prestation_to_clone}, 'prestation_types', 'users') if $_REQUEST {id_prestation_to_clone};

	if ($_USER -> {id_site}) {
	
		$_USER -> {id_site_group} ||= sql_select_scalar ('SELECT id_site_group FROM sites WHERE id = ?', $_USER -> {id_site});
	
	}
	
	$_USER -> {id_site_group} += 0;

	my $sites = sql_select_vocabulary (sites => {
	
		filter => $_USER -> {id_site_group} ?
		
			"id_site_group   = $_USER->{id_site_group}" :

			"id_organisation = $_USER->{id_organisation}"

	});

	my @menu = ({
		label     => $_USER -> {id_site_group} ? sql_select_scalar ('SELECT label FROM site_groups WHERE id = ?', $_USER -> {id_site_group}) : 'Tous sites',
		href      => {id_site => '', aliens => ''},
		is_active => !$_REQUEST {id_site} && !$_REQUEST {aliens},
	});
	
	foreach my $site (@$sites) {
	
		push @menu, {
			label     => $site -> {label},
			href      => {id_site => $site -> {id}, aliens => ''},
			is_active => $_REQUEST {id_site} == $site -> {id} && !$_REQUEST {aliens},
		};
	
	}
	
	if (@menu == 1) {
		
		$menu [0] -> {label} = 'Prestations locales',
		
	}


	my $site_filter = '';
	
	if ($_REQUEST {id_site}) {
		
		$site_filter = " AND IFNULL(id_site, 0) IN ($_REQUEST{id_site}, 0) ";
		
	}
	elsif ($_USER -> {id_site_group}) {
	
		my $ids = sql_select_ids ('SELECT id FROM sites WHERE fake = 0 AND id_site_group = ?', $_USER -> {id_site_group});
		
		$site_filter = " AND IFNULL(id_site, 0) IN ($ids, 0) ";
		
	}

	$_REQUEST {__meta_refresh} = $_USER -> {refresh_period} || 300;
	
	my $default_color = sql_select_scalar ('SELECT color FROM prestation_type_groups WHERE id = -1');
	my $busy_color    = sql_select_scalar ('SELECT color FROM prestation_type_groups WHERE id = -2');

	$_REQUEST {month} =~ /^[1-9]\d?$/ or delete $_REQUEST {year};
	
	unless ($_REQUEST {year}) {	
		($_REQUEST {year}, $_REQUEST {month}) = Today ();	
	}
		
	my $prev = [Add_Delta_YM ($_REQUEST {year}, $_REQUEST {month}, 1, 0, -1)];
	my $next = [Add_Delta_YM ($_REQUEST {year}, $_REQUEST {month}, 1, 0, +1)];
	
	my @days = ();
	
	my $ix_days = {};
	
	my $organisation = sql_select_hash (organisations => $_USER -> {id_organisation});

	my %wd = map {$_ => 1} split ',', $organisation -> {days};
	
	my ($y, $m) = ($_REQUEST {year}, $_REQUEST {month}, 1);
	
	my $number_of_days = 0;
	
	my $days_in_month = Days_in_Month ($y, $m);
	
	foreach my $d (1 .. $days_in_month) {
	
		my $day_index = Day_of_Week ($y, $m, $d);
			
		$wd {$day_index} or next;

		$number_of_days ++;
		
		my $iso_dt = sprintf ('%04d-%02d-%02d', $y, $m, $d);
		my $fr_dt = sprintf ('%02d/%02d/%04d', $d, $m, $y);

		push @days, {
			id => 2 * ($d + 1),
			iso_dt => $iso_dt,
			fr_dt => $fr_dt,
			label => $d,
			date  => [$y, $m, $d],
			half  => 1,
		};

		$ix_days -> {$iso_dt . '-' . 1} = $days [-1];
	
		if (@days > 1) {
			$days [-2] -> {next} = $days [-1];
		}

		push @days, {
			id => 2 * ($d + 1) + 1,
			iso_dt => $iso_dt,
			fr_dt => $fr_dt,
			label => $d,
			date  => [$y, $m, $d],
			half  => 2,
		};

		$ix_days -> {$iso_dt . '-' . 2} = $days [-1];

		$days [-2] -> {next} = $days [-1];

	}
	
	my ($week_from, $year_from) = Week_of_Year ($y, $m, 1);
	$year_from == $y or $week_from = 1;
	
	my ($week_to,   $year_to)   = Week_of_Year ($y, $m, $days_in_month);	
	$year_to   == $y or $week_to   = 53;

	my $holydays = {};
		
	sql_select_loop ("SELECT *, dt + INTERVAL 1 YEAR AS dt FROM holydays WHERE fake = 0 AND id_organisation = ? AND is_every_year = 1 AND dt BETWEEN ? - INTERVAL 1 YEAR AND ? - INTERVAL 1 YEAR"
		, sub {
			sql_select_id ('holydays', {
				-fake           => 0,
				dt              => $i -> {dt},
				is_every_year   => 1,
				label           => $i -> {label},
				id_organisation => $_USER -> {id_organisation},
			}, ['dt', 'id_organisation'])
		}
		, $_USER -> {id_organisation}
		, $days [0] -> {iso_dt}
		, $days [-1] -> {iso_dt}
	);
	
	sql_select_loop ("SELECT * FROM holydays WHERE fake = 0 AND id_organisation = ? AND dt BETWEEN ? AND ?", sub {$holydays -> {$i -> {dt}} = $i}, $_USER -> {id_organisation}, $days [0] -> {iso_dt}, $days [-1] -> {iso_dt});
	
#	my $week_status_type = sql_select_hash ('week_status_types', week_status ($days [0] -> {fr_dt}));
	
#	if (is_past ($days [0] -> {fr_dt})) {		
#		$week_status_type -> {switch} = $week_status_type -> {id} == 3 ?
#			{id => 2, icon => 'tv_0', label => 'Réactiver'} :
#			{id => 3, icon => 'tv_1', label => 'Cloîtrer'}  ;					
#	}
#	else {
#		$week_status_type -> {switch} = $week_status_type -> {id} == 1 ?
#			{id => 2, icon => 'tv_0', label => 'Publier'}   :
#			{id => 1, icon => 'tv_1', label => 'Cacher'}    ;
#	}


	my $dt_start  = $days [0]  -> {iso_dt};
	my $dt_finish = $days [-1] -> {iso_dt};

	my $ids_partners = $organisation -> {ids_partners} || '-1';
darn $ids_partners;
	my $ids_alien_types = -1;
	my $ids_alien_partnerships = -1;
	
#$time = __log_profilinig ($time, '      1');

	if ($ids_partners ne '-1') {

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

	$_USER -> {id_organisation} += 0;

#	if ($week_status_type -> {id} != 1 || $_USER -> {role} eq 'admin') {
#	
		$ids_partners .= ",$_USER->{id_organisation}";
#	
#	}
	
#$time = __log_profilinig ($time, '      3');

	my $prestations = $ids_partners eq '-1' ? [] :
		
		sql_select_all (darn <<EOS);
			SELECT STRAIGHT_JOIN
				prestations.id
				, prestations.id_user
				, prestations.id_users
				, prestations.note
				, prestations.id_prestation_model
				, prestations.id_prestation_type
				, prestation_types.label_3 AS label
				, prestation_types.is_half_hour
				, prestation_types.is_placeable_by_conseiller
				, prestation_types.ids_users
				, prestation_types.id_organisation
				, prestation_types.length + prestation_types.length_ext AS length
				, IF(prestations.dt_start < '$dt_start', '$dt_start', prestations.dt_start) AS dt_start
				, IF(prestations.dt_start < '$dt_start', 1, prestations.half_start) AS half_start
				, IF(prestations.dt_finish > '$dt_finish', '$dt_finish', prestations.dt_finish) AS dt_finish
				, IF(prestations.dt_finish > '$dt_finish', 2, prestations.half_finish) AS half_finish
				, IFNULL(prestation_type_group_colors.color, prestation_type_groups.color) AS color
				, IF(prestations.id_organisation = $_USER->{id_organisation}, 0, 1) AS is_alien
				, IF(prestations.id_organisation = $_USER->{id_organisation}, '', organisations.label) AS inscriptions
			FROM
				prestations_weeks
				INNER JOIN prestations ON (
					prestations_weeks.id_prestation = prestations.id
					AND (
						prestations.id_organisation = $_USER->{id_organisation}
						OR prestations.id_prestation_partnership IN ($ids_alien_partnerships)
						OR (
							prestations.id_prestation_partnership IS NULL
							AND prestations.id_prestation_type IN ($ids_alien_types)
						)
					)
				)
				LEFT  JOIN prestation_types       ON prestations.id_prestation_type = prestation_types.id
				LEFT  JOIN prestation_type_groups ON prestation_types.id_prestation_type_group = prestation_type_groups.id
				LEFT  JOIN prestation_type_group_colors ON (
					prestation_type_group_colors.id_prestation_type_group = prestation_type_groups.id
					AND prestation_type_group_colors.id_organisation = $_USER->{id_organisation}
				)
				LEFT JOIN organisations ON prestation_types.id_organisation = organisations.id
			WHERE
				prestations_weeks.year = $_REQUEST{year}
				AND (prestations_weeks.week BETWEEN $week_from AND $week_to)
				AND prestations_weeks.id_organisation IN ($ids_partners)
				@{[$_REQUEST{only_rh} ? ' AND prestation_types.is_rh = 1 ' : '']}
EOS

	my @alien_id_users = (-1);	
	
	foreach my $prestation (@$prestations) {
		next if $prestation -> {id_organisation} == $_USER -> {id_organisation};
		push @alien_id_users, $prestation -> {id_user};
		push @alien_id_users, (split /\,/, $prestation -> {id_users});	
	}

	my $alien_id_users = join ',', grep {$_} @alien_id_users;	
		
	my $filter = '';
	my @params = ();
	
	unless ($_USER -> {role} eq 'admin') {
		$filter .= ' AND (IFNULL(roles.is_hidden, 0) = 0 OR users.id_group = ?)';
		push @params, 0 + $_USER -> {id_group};
	}
	
	if ($_REQUEST {only_persons}) {
		$filter .= ' AND users.is_person = 1';
	}

#$time = __log_profilinig ($time, '      4');
	my $users = sql_select_all (<<EOS, $days [-1] -> {iso_dt}, $days [0] -> {iso_dt}, $_USER -> {id_organisation}, @params);
		SELECT STRAIGHT_JOIN
			users.id
			, users.id_site
			, IFNULL(prenom, users.label) AS label
			, dt_start - INTERVAL 1 DAY  AS dt_start
			, dt_finish + INTERVAL 1 DAY AS dt_finish
			, roles.id AS id_role
			, sites.label AS site_label
			, IF(users.id_organisation = $$_USER{id_organisation}, roles.label, organisations.label) AS role
			, IF(users.id_organisation = $$_USER{id_organisation}, 0, 1) AS is_alien
		FROM
			users
			INNER JOIN groups AS roles ON users.id_group = roles.id
			INNER JOIN organisations ON users.id_organisation = organisations.id
			LEFT  JOIN sites ON users.id_site = sites.id
		WHERE
			users.fake = 0
			$site_filter
			AND (dt_start  IS NULL OR dt_start  <= ?)
			AND (dt_finish IS NULL OR dt_finish >= ?)
			AND (roles.id_organisation = ? OR (users.id IN ($alien_id_users) AND users.id_role < 3))
			$filter
		ORDER BY
			IF(users.id_organisation = $$_USER{id_organisation}, 0, 1)
			, organisations.label
			, roles.ord
			, roles.label
			, prenom
EOS
#$time = __log_profilinig ($time, '      5');
	my @users = ();
	my $last_role = '';
	
	foreach my $user (@$users) {
	
		$item -> {has_aliens} ||= $user -> {is_alien};
		
		$user -> {is_alien} == $_REQUEST {aliens} or next;
	
		my $role = $user -> {role};
		
#		unless ($user -> {is_alien}) {
#			$role =~ s{^(\S+)}{$1s};
#		}
		
		$last_role eq $role or push @users, {id => 0, label => $role};
		
		$user -> {title} = $user -> {label};

		!$user -> {id_site} or $user -> {id_site} == $_REQUEST {id_site} or $user -> {title} .= " - $user->{site_label}";

		push @users, $user;
		
		$last_role = $role;
		
	}
	
	if ($item -> {has_aliens}) {
	
		push @menu, {
			label     => 'Partenaires',
			href      => {id_site => '', aliens => 1},
			is_active => $_REQUEST {aliens},
		};
	
	}
	
	if (!$_REQUEST {only_persons} && !$_REQUEST {aliens} && !$item -> {inscription_to_clone} && !$item -> {prestation_to_clone}) {
	
		push @users, {label => 'Ressources'};
		push @users, @{ sql_select_all ("SELECT -id AS id, label FROM rooms WHERE fake = 0 $site_filter AND id_organisation = ? ORDER BY label", $_USER -> {id_organisation})};
	
	}
	
	$users = \@users;	

	my $prestations_rooms = [];

	if (!$_REQUEST {only_persons} && !$_REQUEST {aliens} && ($week_status_type -> {id} != 1 || $_USER -> {role} eq 'admin')) {
								
		$prestations_rooms = sql_select_all (<<EOS, $_USER -> {id_organisation});
			SELECT
				prestations.id
				, prestations.note
				, - prestations_rooms.id_room AS id_user
				, prestation_types.label_3 AS label
				, prestation_types.is_half_hour
				, prestation_types.is_placeable_by_conseiller
				, prestation_types.ids_users
				, prestation_types.length + prestation_types.length_ext AS length
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
	
	if ($item -> {inscription_to_clone}) {
	
		$prestations = [grep {$_ -> {id_prestation_type} == $item -> {inscription_to_clone} -> {id_prestation_type}} @$prestations]
	
	}
		
	my ($ids, $idx) = ids ($prestations);
	
#$time = __log_profilinig ($time, '      8');

	foreach my $i (@{sql_select_all ("SELECT id_prestation, COUNT(*) AS cnt, SUM(IF(fake = 0, 0, 1)) AS cnt_fake FROM inscriptions WHERE id_prestation IN ($ids) AND label NOT LIKE '+%' GROUP BY 1")}) {

			my $prestation = $idx -> {$i -> {id_prestation}};
			
			if ($prestation -> {is_half_hour} != -1) {
				$prestation -> {cnt_inscriptions_total} += $i -> {cnt};
				$prestation -> {cnt_fake} = $i -> {cnt_fake};
			}

	}
	
#$time = __log_profilinig ($time, '      9');

	foreach my $i (@{sql_select_all
			
		"SELECT id_prestation, label, prenom, nom FROM inscriptions WHERE id_prestation IN ($ids) AND fake = 0 ORDER BY id"
		
	}){
					
			my $prestation = $idx -> {$i -> {id_prestation}};

			if ($prestation -> {is_half_hour} != -1 && $i -> {label} !~ /^\+/) {
				$prestation -> {cnt_inscriptions} ++;
			}

			next if $prestation -> {is_alien};
			
			$prestation -> {inscriptions} .= ', ' if $prestation -> {inscriptions};
			$prestation -> {inscriptions} .= "$i->{prenom} $i->{nom}";
						
	};
							
#$time = __log_profilinig ($time, '      10');
	my @prestations = ();	
	my @holydays = sort keys %$holydays;
		
	PRESTATION: foreach my $prestation (@$prestations, @$prestations_rooms) {
	
		next if $item -> {inscription_to_clone} && !$prestation -> {cnt_fake};
	
	        foreach my $holyday (@holydays) {
	
	        	next if $holyday lt $prestation -> {dt_start};
	        	next if $holyday gt $prestation -> {dt_finish};
	        	
	        	next PRESTATION if $prestation -> {dt_start} eq $prestation -> {dt_finish};
	        	
	        	if ($holyday gt $prestation -> {dt_start}) {
	        					
				my $slice = {%$prestation};	
		        	$slice -> {dt_finish} = sprintf ('%04d-%02d-%02d', Add_Delta_Days ((split /-/, $holyday), -1));
		        	$slice -> {half_finish} = 2;
			
				push @prestations, $slice;

			}
						
	        $prestation -> {dt_start} = sprintf ('%04d-%02d-%02d', Add_Delta_Days ((split /-/, $holyday), 1));
	        $prestation -> {half_start} = 1;

			next PRESTATION if $prestation -> {dt_start} . $prestation -> {half_start} gt $prestation -> {dt_finish} . $prestation -> {half_finish};
	
		}
		
		push @prestations, $prestation;
	
	}	

#$time = __log_profilinig ($time, '      11');
	foreach my $prestation (@prestations) {
	
		$prestation -> {no_href} = 1 if !$prestation -> {length} && $prestation -> {is_half_hour} != -1;
				
		$have_models ||= $prestation -> {id_prestation_model};
	
		my @id_users = grep {$_ > 0} split /\,/, $prestation -> {id_users};
		push @id_users, $prestation -> {id_user};
		
		if ($prestation -> {is_half_hour} != -1) {

			if (
				$prestation -> {cnt_inscriptions_total}
				&& $prestation -> {cnt_inscriptions_total} <= $prestation -> {cnt_inscriptions})
			{
				$prestation -> {color} = $busy_color;
			}		
			elsif ($prestation -> {is_half_hour}) {
#				$bgcolor = sql_select_scalar ('SELECT COUNT(*) FROM inscriptions WHERE fake <> 0 AND id_prestation = ?', $prestation -> {id}) ? '#ddffdd' : '#ffdddd',
				$bgcolor = $prestation -> {cnt_fake} ? '#ddffdd' : '#ffdddd',
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
				no_href                       => $prestation -> {no_href},
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
#$time = __log_profilinig ($time, '      12');
	
	my $id_users = join ',', (-1, grep {$_ > 0} map {$_ -> {id}} @$users);
	
#	my $off_periods = sql_select_all (<<EOS);
#		SELECT
#			off_periods.id
#			, off_periods.id_user
#			, IF(off_periods.dt_start  < '$dt_start',  '$dt_start',  off_periods.dt_start)    AS dt_start
#			, IF(off_periods.dt_start  < '$dt_start',  1,            off_periods.half_start)  AS half_start
#			, IF(off_periods.dt_finish > '$dt_finish', '$dt_finish', off_periods.dt_finish)   AS dt_finish
#			, IF(off_periods.dt_finish > '$dt_finish', 2,            off_periods.half_finish) AS half_finish
#		FROM
#			off_periods
#		WHERE
#			off_periods.fake = 0
#			AND off_periods.dt_start  <= '$dt_finish'
#			AND off_periods.dt_finish >= '$dt_start'
#			AND off_periods.id_user IN ($id_users)
#EOS
#
#	foreach my $user (@$users) {
#	
#		if ($user -> {dt_start} && $user -> {dt_start} ge $days [0] -> {iso_dt}) {
#		
#			push @$off_periods, {
#				id => -1,
#				id_user => $user -> {id},
#				dt_start => $days [0] -> {iso_dt},
#				dt_finish => $user -> {dt_start},
#				half_start => 1,
#				half_finish => 2,
#			};
#
#		}
#
#		if ($user -> {dt_finish} && $user -> {dt_finish} le $days [-1] -> {iso_dt}) {
#		
#			push @$off_periods, {
#				id => -1,
#				id_user => $user -> {id},
#				dt_start => $user -> {dt_finish},
#				dt_finish => $days [-1] -> {iso_dt},
#				half_start => 1,
#				half_finish => 2,
#			};
#			
#		}
#		
#	}

	if (@$off_periods) {
	
		my $user2ord = {};	
	    for (my $i = 0; $i < @$users; $i++) { $user2ord -> {$users -> [$i] -> {id}} = $i };

		my $day2ord = {};	
		
	    for (my $i = 0; $i < @days; $i++) { $day2ord -> {$days [$i] -> {iso_dt}} = $i };
	
	    	foreach my $off_period (@$off_periods) {

			my %hdays = ();
	
			for (my $i = 0; $i < @days; $i++) {
				$days [$i] -> {by_user} -> {$off_period -> {id_user}} -> {rowspan} ||= ($holydays -> {$days [$i] -> {iso_dt}} ? 2 : 1);
			}
						
			for (my $i = 0; $i < @days; $i++) {

				my $day = $days [$i];
				
				my $dt = $day -> {iso_dt};				
								

				if ($dt lt $off_period -> {dt_start}) {
					$hdays {$dt} ||= 1 if $holydays -> {$dt};
					next;
				}

				$off_period -> {col_start} =
					$i
					+ $off_period -> {half_start}
					- %hdays
					;
				last;

			};
	
			my %hdays = ();

			for (my $i = 0; $i < @days; $i++) {
	
				my $day = $days [$i];

				my $dt = $day -> {iso_dt};
				
				if ($dt lt $off_period -> {dt_finish}) {
					$hdays {$dt} ||= 1 if $holydays -> {$dt};
					next;
				}
	
				$off_period -> {col_finish} =
					$i
					+ $off_period -> {half_finish}
					- %hdays
					;

				last;

			};

			$off_period -> {row}        = 0 + $user2ord -> {$off_period -> {id_user}};

		};
	
	}
#$time = __log_profilinig ($time, '      15');
	if ($_USER -> {role} eq 'admin') {
	
		$_USER -> {can_dblclick_others_empty} = 1;
	
	}
	else {

		my $sql = 'SELECT COUNT(*) FROM prestation_types WHERE fake = 0 AND is_placeable_by_conseiller IN (2, 3) AND ids_users LIKE ?';
		
		if ($_REQUEST {id_prestation_to_clone}) {
		
			$sql .= " AND id = $item->{prestation_to_clone}->{id_prestation_type}"
		
		}
		elsif ($_REQUEST {id_prestation_type}) {
		
			$sql .= " AND id = $_REQUEST{id_prestation_type}";
		
		}
		
		$_USER -> {cnt_prestation_types} = sql_select_scalar ($sql, '%,' . $_USER -> {id} . ',%');
		
		$_USER -> {can_dblclick_others_empty} = $_USER -> {cnt_prestation_types} > 0;

	}

	my $data = {
	
		number_of_days => $number_of_days,
	
		week_status_type => $week_status_type,
	
		days => \@days,
		
		prev => $prev,
		
		next => $next,
		
		users => $users,
		
		off_periods => $off_periods,
		
		prestation_types => sql_select_vocabulary (
			prestation_types => {filter => 'id_organisation=' . $_USER -> {id_organisation} . ' AND ' . ($_USER -> {role} ne 'conseiller' ? '1=1' : "is_placeable_by_conseiller IN (1, 3) OR ids_users LIKE '%,$$_USER{id},%'")},
		),

		day_periods => sql_select_vocabulary ('day_periods', {order => 'id'}),
		
		have_models => $have_models,

		menu => @menu > 1 ? \@menu : undef,
		
		holydays => $holydays,
		
		organisation => $organisation,
		
		%$item,
			
	};
	
	if (	
		$_USER -> {role} eq 'admin'
		&& !$_REQUEST {id_inscription_to_clone}
		&& !$_REQUEST {id_prestation_to_clone}
	) {
		
		sql ($data, models => [
			
			[id_organisation => $organisation -> {id}],
			[is_odd          => [-1, $_REQUEST {week} % 2]],
			
		]);
		
	}

	return $data;

}

1;

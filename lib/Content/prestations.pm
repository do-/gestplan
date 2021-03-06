################################################################################

sub recalculate_prestations {

	sql_do (qq {
	
		UPDATE
			prestations
			LEFT JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
		SET
			prestations.id_organisation = prestation_types.id_organisation
		WHERE
			prestations.id_organisation IS NULL
	
	});
	
	if ($_REQUEST {id}) {
	
		my $data = sql (prestations => $_REQUEST {id});
		
		my ($w, $y) = Week_of_Year (dt_y_m_d ($data -> {dt_start}));

		my ($wf, $yf) = Week_of_Year (dt_y_m_d ($data -> {dt_finish}));

		my @prestations_weeks = ();

		while ($y < $yf or ($y == $yf and $w <= $wf)) {
		
			push @prestations_weeks, {
			    fake            => 0,
				year            => $y,
				week            => $w,
				id_organisation => $data -> {id_organisation},
			};
		
			($w, $y) = Week_of_Year (Add_Delta_Days (Monday_of_Week ($w, $y), 7));
		
		}
		
		wish (table_data => \@prestations_weeks, {
			
			table   => 'prestations_weeks',
			root    => {id_prestation => $data -> {id}},
			key     => 'year,week',	

		});
	
	}

}

################################################################################

sub _validate_clone_prestations {

	my $id = sql ('prestations(id)' => ['id_user', 'dt_start', 'half_start', ['1 ']]);

	if ($id) {
	
		my $h = {href => "/?type=prestations&id=$id"};
		
		check_href ($h);
		
		out_html ({}, "nope ('$h->{href}', '_self')");

		return undef;
	
	}

	my $data = sql (prestations => $_REQUEST {id}, 'prestation_types', 'organisations');

	if ($data -> {prestation_type} -> {id_day_period} == 1) {
		$_REQUEST {half_start} == 1 or return "Ce type de prestation ne peut pas commencer l'apr�s-midi";
	}

	if ($data -> {prestation_type} -> {id_day_period} == 2) {
		$_REQUEST {half_start} == 2 or return "Ce type de prestation ne peut pas commencer le matin";
	}
	
	if ($data -> {dt_start} . $data -> {half_start} ne $data -> {dt_finish} . $data -> {half_finish}) {
	
		my $delta_half_days =
			2 * Delta_Days (dt_y_m_d ($data -> {dt_start}), dt_y_m_d ($data -> {dt_finish}))
			  + $data -> {half_finish} - $data -> {half_start}
		;

		my @dt   = dt_y_m_d ($_REQUEST {dt_start});
		my $half = $_REQUEST {half_start};
		
		if ($half == 2) {
		
			@dt = Add_Delta_Days (@dt, 1);
			
			$half = 1;
			
			$delta_half_days --;
		
		}
		
		@dt = Add_Delta_Days (@dt, int ($delta_half_days / 2));
		
		$half += ($delta_half_days % 2);
		
		$_REQUEST {dt_finish}   = dt_iso (@dt);

		$_REQUEST {half_finish} = $half;
	
	}
	
	if ($data -> {dt_start} . $data -> {half_start} ne $data -> {dt_finish} . $data -> {half_finish}) {
	
		my $delta_half_days =
			2 * Delta_Days (dt_y_m_d ($data -> {dt_start}), dt_y_m_d ($data -> {dt_finish}))
			  + $data -> {half_finish} - $data -> {half_start}
		;

		my @dt   = dt_y_m_d ($_REQUEST {dt_start});
		my $half 	 = $_REQUEST {half_start};
		
		if ($half == 2) {
		
			@dt = Add_Delta_Days (@dt, 1);
			
			$half = 1;
			
			$delta_half_days --;
		
		}
		
		@dt = Add_Delta_Days (@dt, int ($delta_half_days / 2));
		
		$half += ($delta_half_days % 2);
		
		$_REQUEST {dt_finish}   = dt_iso (@dt);

		$_REQUEST {half_finish} = $half;
	
	}
	
	my $user = sql (users => $_REQUEST {id_user});

	$data -> {prestation_type} -> {ids_roles} =~ /\,$user->{id_role}\,/ or return "D�sol�, mais $user->{label} ne peut pas assister aux prestations $data->{prestation_type}->{label_short}.";
			
	0 == sql_select_scalar (
	
		q {
			SELECT
				id
			FROM
				prestations
			WHERE
				1 = 1
				AND id_user = ?
				AND fake = 0
				AND CONCAT(dt_start,  half_start)  <= ?
				AND CONCAT(dt_finish, half_finish) >= ?
				AND dt_finish >= ?
			LIMIT
				1
		},

		$user  -> {id},
		$_REQUEST {dt_finish} . $_REQUEST {half_finish},
		$_REQUEST {dt_start}  . $_REQUEST {half_start},
		$_REQUEST {dt_start}
		
	) or return "D�sol�, mais $user->{label} est occup�(e) pendant cette p�riode.";
	
	my @id_prestations_rooms = sql_select_col ('SELECT id_room FROM prestations_rooms WHERE id_prestation = ? AND id_room > 0', $_REQUEST {id});
	
	if (@id_prestations_rooms) {
	
		my $ids = join ',', @id_prestations_rooms;
		
		my $conflict = sql_select_hash (qq {
				SELECT
					prestations_rooms.id
					, rooms.label
					, prestations_rooms.dt_start
					, prestations_rooms.dt_finish
				FROM
					prestations_rooms
					LEFT JOIN prestations ON prestations_rooms.id_prestation = prestations.id
					LEFT JOIN rooms ON prestations_rooms.id_room = rooms.id
				WHERE
					prestations_rooms.fake = 0
					AND prestations.fake = 0
					AND prestations_rooms.id_room IN ($ids)
					AND CONCAT(prestations_rooms.dt_start, prestations_rooms.half_start) <= ?
					AND CONCAT(prestations_rooms.dt_finish, prestations_rooms.half_finish) >= ?
					AND prestations_rooms.dt_finish >= ?
				LIMIT
					1
			},
			$_REQUEST {dt_finish} . $_REQUEST {half_finish},
			$_REQUEST {dt_start}  . $_REQUEST {half_start},
			$_REQUEST {dt_start},
			
		);		
	
		if ($conflict -> {id}) {
		
			__d ($conflict, 'dt_start', 'dt_finish');
			
			return "Conflit de r�servation pour $conflict->{label}";
			
		}
	
	}

	undef;

}

################################################################################

sub do_clone_prestations { # duplication

	my $e = _validate_clone_prestations ();

	if ($e) {	
		my $a = $_JSON -> encode ([$e]);
		out_html ({}, "var a = $a; alert (a[0]);");	
	}

	return if $_REQUEST {__response_sent};

	my $data = sql (prestations => $_REQUEST {id});
	
	my $type = sql (prestation_types => $data -> {id_prestation_type}, 'prestation_type_groups');
	
	$_REQUEST {fake} = '0,-1';
	
	my $inscriptions = sql (inscriptions => [[id_prestation => $data -> {id}], [ORDER => 'id']]);

	my $delta_minutes =
		!$type -> {is_half_hour}                        ? 0 :
		$data -> {half_start} == $_REQUEST {half_start} ? 0 :
		60 * ($type -> {"half_$_REQUEST{half_start}_h"} - $type -> {"half_$data->{half_start}_h"})
		   + ($type -> {"half_$_REQUEST{half_start}_m"} - $type -> {"half_$data->{half_start}_m"})
	;

	delete $data -> {$_}           foreach qw (id id_users);
	
	$data -> {$_} = $_REQUEST {$_} foreach qw (dt_start half_start dt_finish half_finish id_user);
	
	$data -> {id} = sql_do_insert (prestations => $data);
	
	foreach my $inscription (@$inscriptions) {
	
		my $id = delete $inscription -> {id};
	
		delete $inscription -> {$_} foreach qw (parent id_user hour minute id_log);
		
#		$inscription -> {id_author}     = $_USER -> {id};
		
		$inscription -> {id_prestation} = $data  -> {id};
		
		if ($delta_minutes && $inscription -> {label} =~ /^\s*(\d+)h(\d+)/) {
		
			my $m = 60 * $1 + $2 + $delta_minutes;
			
			$inscription -> {label} = sprintf ('%2dh%02d', int ($m / 60), $m % 60);
		
		}
		
		$inscription -> {id} = sql_do_insert (inscriptions => $inscription);
		
		sql (ext_field_values => [[id_inscription => $id]], sub {
		
			delete $i -> {id};
			
			$i -> {id_inscription} = $inscription -> {id};
			
			sql_do_insert (ext_field_values => $i);
		
		})
	
	}
	
	my @ids_users = ($_REQUEST {id_user});

	sql (prestations_rooms => [[id_prestation => $_REQUEST {id}]], sub {
	
		delete $i -> {id};
		
		push @ids_users, -1 * $i -> {id_room};
		
		$i -> {id_prestation} = $data -> {id};
		
		$i -> {$_} = $_REQUEST {$_} foreach qw (dt_start half_start dt_finish half_finish);
		
		sql_do_insert (prestations_rooms => $i);
	
	});
	
	$_REQUEST {id} = $data -> {id};
	
	if (
			$type -> {id}
		&& !$type -> {is_multiday}
		&& !$type -> {is_to_edit}
		&&  $type -> {id_people_number} < 3
	) {
		
		$data -> {half}                 	   = $data -> {half_start};
		$data -> {label_short}                 = $type -> {label_short};
		$data -> {color}                       = $type -> {prestation_type_group} -> {color};
		$data -> {no_href}                     = (!$type -> {length} && $type -> {is_half_hour} != -1) || $_REQUEST {id_user} < 0;
		$data -> {id_user}                     = $_REQUEST {id_user};
		$data -> {ids_users}                   = \@ids_users;
		$data -> {__last_scrollable_table_row} = $_REQUEST {__last_scrollable_table_row};
		$data -> {__last_query_string}         = $_REQUEST {__last_query_string};

		my $j = $_JSON -> encode ($data);
				
		my $s = "set_cell($j)";
	
		out_html ({}, $s);

	}
				
	my $h = esc_href ();
	
	out_html ({}, "nope ('$h', '_self')");	

}

################################################################################

sub do_erase_prestations {

	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my $from = sprintf ('%04d-%02d-%02d', @monday);
	my $to   = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, 6));
	
	my $sql = <<EOS;
		SELECT
			prestations.id
			, prestations.id_user
			, prestations.id_users
		FROM
			prestations
			INNER JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
		WHERE
			1=1
			AND prestations.dt_start  <= ?
			AND prestations.dt_finish >= ?
			AND (prestations.id_user = ? OR CONCAT(',', prestations.id_users, ',') LIKE ?)
EOS
	
	my $ids = -1;
	
	foreach my $i (@{sql_select_all ($sql, $to, $from, $_REQUEST {id_user}, '%,' . $_REQUEST {id_user} . ',%')}) {

		my @ids_users = grep {$_ != $_REQUEST {id_user}} grep {$_ > 0} ($i -> {id_user}, split /\,/, $i -> {id_users});

		if (@ids_users) {
		
			my $id_user = shift @ids_users;
			
			sql_do ('UPDATE prestations SET id_user = ?, id_users = ? WHERE id = ?', $id_user, (join ',', (-1, @ids_users, -1)), $i -> {id});
		
		}
		else {

			$ids .= ",$i->{id}";

		}
	
	}

	if ($ids ne '-1') {

		sql_do ("DELETE FROM prestations WHERE id IN ($ids)");
		sql_do ("DELETE FROM inscriptions WHERE id_prestation IN ($ids)");
		sql_do ("DELETE FROM prestations_rooms WHERE id_prestation IN ($ids)");
		sql_do ("DELETE FROM prestations_weeks WHERE id_prestation IN ($ids)");

	}
	
	delete $_REQUEST {id_user};
	
}

################################################################################

sub do_clear_prestations {

	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my $from = sprintf ('%04d-%02d-%02d', @monday);
	my $to   = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, 6));
	
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
	sql_do ("DELETE FROM prestations_rooms WHERE id_prestation IN ($ids)");
	sql_do ("DELETE FROM prestations_weeks WHERE id_prestation IN ($ids)");
	
}

################################################################################

sub validate_add_models_prestations {

	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my $prestation_models = sql_select_all (<<EOS, $_REQUEST {id_model}, {fake => 'prestation_models'});
		SELECT
			prestation_models.*
			, prestation_types.is_collective
		FROM
			prestation_models
			INNER JOIN users ON prestation_models.id_user = users.id
			LEFT  JOIN prestation_types ON prestation_models.id_prestation_type = prestation_types.id
		WHERE
			prestation_models.id_model = ?
EOS

	if ($_REQUEST {id_user}) {
		
		$prestation_models = [grep {$_ -> {id_user} == $_REQUEST {id_user} or $_ -> {id_users} =~ /\b$_REQUEST{id_user}\b/} @$prestation_models];
	
	}

	my $prestation_types = {};
	
	my $day_periods = sql_select_all_hash ('SELECT id, label FROM day_periods');
			
	foreach my $prestation_model (@$prestation_models) {
	
		my $dt = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, $prestation_model -> {day_start} - 1));
		my $dt_fr = join '/', reverse split /-/, $dt;
		$dt_fr .= " $day_periods->{$prestation_model->{half_start}}->{label}";

		my $type = (
			$prestation_types -> {$prestation_model -> {id_prestation_type}} ||=
			sql_select_hash ('prestation_types', $prestation_model -> {id_prestation_type})
		);
	
		my $conflict = sql_select_hash (<<EOS, $_USER -> {id_organisation}, $dt, $dt, "${dt}$prestation_model->{half_finish}", "${dt}$prestation_model->{half_start}", $prestation_model -> {id_user}, "\%,$prestation_model->{id_user},\%");
			SELECT 	
				prestations.*
			FROM
				prestations
			WHERE
				fake = 0
				AND id_organisation = ?
				AND dt_start  <= ?
				AND dt_finish >= ?
				AND CONCAT(dt_start,  half_start)  <= ?
				AND CONCAT(dt_finish, half_finish) >= ?
				AND (id_user = ? OR IFNULL(id_users, '') LIKE ?)
			LIMIT 1
EOS

        	if ($conflict -> {id}) {
        		
			my $user = sql_select_hash ('users', $prestation_model -> {id_user});
			        	
        		return "D�sol�, mais une prestation pour $user->{label} est d�j� plac�e le $dt_fr";
        	
		}

		foreach my $id_room (grep {$_ > 0} split /\,/, $type -> {ids_rooms}) {
		
			my $conflict = sql_select_hash (<<EOS, $dt, $dt, "${dt}$prestation_model->{half_finish}", "${dt}$prestation_model->{half_start}", $id_room);
				SELECT 	
					prestations_rooms.*
					, prestations.id_prestation_type
				FROM
					prestations_rooms
					LEFT JOIN prestations ON prestations_rooms.id_prestation = prestations.id
				WHERE
					prestations_rooms.fake = 0
					AND prestations_rooms.dt_start  <= ?
					AND prestations_rooms.dt_finish >= ?
					AND CONCAT(prestations_rooms.dt_start,  prestations_rooms.half_start)  <= ?
					AND CONCAT(prestations_rooms.dt_finish, prestations_rooms.half_finish) >= ?
					AND prestations_rooms.id_room = ?
				LIMIT 1
EOS
	
	        $conflict -> {id} or next;
	        
	        !$prestation_model -> {is_collective}
			
				or $prestation_model -> {id_prestation_type} != $conflict -> {id_prestation_type}
				
					or next;

			my $user = sql_select_hash ('users', $prestation_model -> {id_user});
			my $room = sql_select_hash ('rooms', $id_room);
				
			$dt = join '/', reverse split /-/, $dt;
	        	
	        	return "D�sol�, mais la ressource nomm�e '$room->{label}' est occup�(e) le $dt_fr (conflit pour $user->{label})";
	        	
		}		

	}
		
}

################################################################################

sub do_add_models_prestations {

	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});
	
	my %days = ();
	
	my $organisation = sql_select_hash (organisations => $_USER -> {id_organisation});
	
	foreach my $d (split /\,/, $organisation -> {days}) {
	
		my $dt = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, $d - 1));
		
		next if sql_select_scalar ('SELECT id FROM holydays WHERE id_organisation = ? AND dt = ? AND fake = 0', $_USER -> {id_organisation}, $dt);
	
		$days {$dt} = 1;
	
	}
	
	my $prestation_models = sql_select_all (<<EOS, $_REQUEST {id_model}, {fake => 'prestation_models'});
		SELECT
			prestation_models.*
			, prestation_types.is_collective
		FROM
			prestation_models
			INNER JOIN users ON prestation_models.id_user = users.id
			LEFT  JOIN prestation_types ON prestation_models.id_prestation_type = prestation_types.id
		WHERE
			prestation_models.id_model = ?
EOS

	if ($_REQUEST {id_user}) {
		
		$prestation_models = [grep {$_ -> {id_user} == $_REQUEST {id_user} or $_ -> {id_users} =~ /\b$_REQUEST{id_user}\b/} @$prestation_models];
	
	}
	
	my $collective_prestation_types = {-1 => 1};
	
	foreach my $prestation_model (@$prestation_models) {
	
		$prestation_model -> {is_collective} or next;
		
		$collective_prestation_types -> {$prestation_model -> {id_prestation_type}} = 1;
	
	}
	
	my $ids_collective_prestation_types = join ',', keys %$collective_prestation_types;

	my $prestation_types = {};
	
	my $reserved_rooms = {};
	
	my $collective_prestations = {};
		
	sql_select_loop (qq {
	
		SELECT
			prestations.*
		FROM
			prestations_weeks
			LEFT JOIN prestations ON (
				prestations_weeks.id_prestation = prestations.id
				AND prestations.id_prestation_type IN ($ids_collective_prestation_types)
			)
		WHERE prestations_weeks.fake = 0
			AND prestations_weeks.id_organisation = ?
			AND prestations_weeks.year = ?
			AND prestations_weeks.week = ?
	
	}, sub {$collective_prestations -> {1, $i -> {dt_start}, $i -> {half_start}} = $i}, $_USER -> {id_organisation}, $_REQUEST {year}, $_REQUEST {week});
	
	foreach my $prestation_model (@$prestation_models) {
	
		my $dt = sprintf ('%04d-%02d-%02d', Add_Delta_Days (@monday, $prestation_model -> {day_start} - 1));
		
		$days {$dt} or next;

		my $type = (
			$prestation_types -> {$prestation_model -> {id_prestation_type}} ||=
			sql_select_hash ('prestation_types', $prestation_model -> {id_prestation_type})
		);		
		
		if ($type -> {is_collective}) {
		
			my $collective_prestation = $collective_prestations -> {$type -> {is_collective}, $dt, $prestation_model -> {half_start}};
			
			if ($collective_prestation) {
				$collective_prestation -> {id_users} ||= "-1";
				$collective_prestation -> {id_users}  .= ",$prestation_model->{id_user}";
				next;
			}
		
		}
		
		my $id = sql_do_insert ('prestations', {
			fake                => 0,
			dt_start            => $dt,
			half_start          => $prestation_model -> {half_start},
			dt_finish           => $dt,
			half_finish         => $prestation_model -> {half_finish},
			id_user             => $prestation_model -> {id_user},
			id_prestation_type  => $prestation_model -> {id_prestation_type},
			id_prestation_model => $prestation_model -> {id},
			id_organisation     => $type -> {id_organisation},
			cnt                 => 1 + $prestation_model -> {half_finish} - $prestation_model -> {half_start},
		});

		sql_do_insert ('prestations_weeks', {
			fake                => 0,
			year                => $_REQUEST {year},
			week                => $_REQUEST {week},
			id_organisation     => $type -> {id_organisation},
			id_prestation       => $id,
		});
		
		if ($type -> {is_collective}) {
		
			$collective_prestations -> {$type -> {is_collective}, $dt, $prestation_model -> {half_start}} = {id => $id};
		
		}

		my $item = sql_select_hash ('prestations', $id);
						
		$type -> {time_step} ||= 30;
		
		my ($h, $m) = ();
			
		if ($item -> {half_start} == 1) {
			
			if ($type -> {half_1_h}) {
				$h = $type -> {half_1_h};
				$m = $type -> {half_1_m};
			}
			else {
				$h = 9;
				$m = 15;
			}
			
		}
		else {
		
			if ($type -> {half_2_h}) {
				$h = $type -> {half_2_h};
				$m = $type -> {half_2_m};
			}
			else {
				$h = 13;
				$m = 45;
			}
			
		}	
			
		for (my $i = 0; $i < $type -> {length}; $i++) {			
		
			my $label = $type -> {is_half_hour} ? sprintf ('%2dh%02d', $h, $m) : ($i + 1) . '.';
			
			sql_do_insert ('inscriptions', {
				id_prestation => $id,
				label => $label,
				fake  => -1,
			});
			
			$m += $type -> {time_step};
			
			if ($m >= 60) {
				$h += int ($m / 60);
				$m %= 60;
			}
		
		}
		
		for (my $i = 0; $i < $type -> {length_ext}; $i++) {			
		
			my $label = '+' . ($i + 1) . '.';
			
			sql_do_insert ('inscriptions', {
				id_prestation => $id,
				label => $label,
				fake  => -1,
			});
		
		}
								
		foreach my $id_room (grep {$_ > 0} split /\,/, $type -> {ids_rooms}) {
		
			next if $reserved_rooms -> {$id_room, $dt, $prestation_model -> {half_start}};

			sql_do_insert ('prestations_rooms', {
				fake                => 0,
				dt_start            => $dt,
				half_start          => $prestation_model -> {half_start},
				dt_finish           => $dt,
				half_finish         => $prestation_model -> {half_finish},
				id_prestation => $id,
				id_room => $id_room,
			});

			$reserved_rooms -> {$id_room, $dt, $prestation_model -> {half_start}} = 1;

		}

	}
	
	foreach my $collective_prestation (values %$collective_prestations) {

		sql_do ("UPDATE prestations SET id_users = ? WHERE id = ?", "$collective_prestation->{id_users},-1", $collective_prestation -> {id});

	}

	delete $_REQUEST {id_user};
	
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
	sql_do ('DELETE FROM prestations_weeks WHERE id_prestation = ?', $_REQUEST {id});
	sql_do_delete ('prestations');

}

################################################################################

sub do_create_prestations {

	my $prestation_type = sql (prestation_types => $_REQUEST {id_prestation_type} || -1, 'prestation_type_groups');

	my $user = sql_select_hash ($_REQUEST {id_user} > 0 ? 'users' : 'rooms', abs ($_REQUEST {id_user}));

	my ($w, $y) = Week_of_Year (dt_y_m_d ($_REQUEST {dt_start}));
	
	my $dh = $_REQUEST {dt_start} . $_REQUEST {half_start};
	
	my $sql = $_REQUEST {id_user} > 0 ? q {
		
		SELECT
			MAX(prestations.id)
		FROM
			prestations_weeks
			LEFT JOIN prestations ON (
				prestations_weeks.id_prestation = prestations.id
				AND prestations.fake = 0
				AND CONCAT(prestations.dt_start,prestations.half_start)   <= ?
				AND CONCAT(prestations.dt_finish,prestations.half_finish) >= ?
				AND (prestations.id_user = ? OR prestations.id_users LIKE ?)
			)
		WHERE
				prestations_weeks.id_organisation = ?
				AND prestations_weeks.fake = 0
				AND prestations_weeks.year = ?
				AND prestations_weeks.week = ?
	
	} : q {
	
		SELECT
			MAX(prestations.id)
		FROM
			prestations_weeks
			LEFT JOIN prestations_rooms ON (
				prestations_weeks.id_prestation = prestations_rooms.id_prestation
				AND prestations_rooms.fake = 0
				AND CONCAT(prestations_rooms.dt_start,prestations_rooms.half_start)   <= ?
				AND CONCAT(prestations_rooms.dt_finish,prestations_rooms.half_finish) >= ?
				AND (prestations_rooms.id_room = ?)
			)
			LEFT JOIN prestations ON (
				prestations_rooms.id_prestation = prestations.id
				AND prestations.fake = 0
			)
		WHERE
				prestations_weeks.id_organisation = ?
				AND prestations_weeks.fake = 0
				AND prestations_weeks.year = ?
				AND prestations_weeks.week = ?

	};
	
	my @p = $_REQUEST {id_user} > 0 ? ($_REQUEST {id_user}, '%,' . $_REQUEST {id_user} . ',%') : (-1 * $_REQUEST {id_user});

#	sql_do ('LOCK TABLES ' . (join ', ', map {"$_ WRITE"} qw (prestations prestations_weeks prestations_rooms prestation_types rooms sessions inscriptions)));
	
	eval {
		
	$_REQUEST {id} = sql_select_scalar ($sql, $dh, $dh, @p, $user -> {id_organisation}, $y, $w);

	if (!$_REQUEST {id} && $_REQUEST {id_prestation_type} && $_REQUEST {id_user} > 0) {
			
		if ($prestation_type -> {id_day_period} < 3) {		
			if ($prestation_type -> {id_day_period} == 1 && $_REQUEST {half_start} == 2) { die "#_foo#:Les $$prestation_type{label_short} ne peuvent �tre affect�s que les matins"; };
			if ($prestation_type -> {id_day_period} == 2 && $_REQUEST {half_start} == 1) { die "#_foo#:Les $$prestation_type{label_short} ne peuvent �tre affect�s que les apr�s-midis"; };		
		}				
				
		$prestation_type -> {ids_roles} =~ /\,$$user{id_role}\,/ or die "#_foo#:D�sol�, mais $$user{label} ne peut pas assister aux prestations $$prestation_type{label_short}.";

		foreach my $id_room (grep {$_ > 0} split /\,/, $prestation_type -> {ids_rooms}) {
		
			my $room = sql_select_hash ('rooms', $id_room);

			0 == sql_select_scalar (<<EOS, $id_room, $_REQUEST {dt_finish} . $_REQUEST {half_finish}, $_REQUEST {dt_start} . $_REQUEST {half_start}) or die "#_foo#:D�sol�, mais la $$room{label} est occup�e pendant cette p�riode.";
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

	unless ($_REQUEST {id}) {

		my @ids_rooms = grep {$_ > 0} split /\,/, $prestation_type -> {ids_rooms};
		push @ids_rooms, - $_REQUEST {id_user} if $_REQUEST {id_user} < 0;

		$_REQUEST {id} = sql_do_insert ('prestations', {
			id_user => $_REQUEST {id_user},
			dt_start => $_REQUEST {dt_start},
			half_start => $_REQUEST {half_start},
			dt_finish => $_REQUEST {dt_finish},
			half_finish => $_REQUEST {half_finish},
			id_prestation_type => $_REQUEST {id_prestation_type},
			id_organisation => $_USER -> {id_organisation},
		});
				
		foreach my $id_room (@ids_rooms) {
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

			$_REQUEST {"_$_"} = $_REQUEST {$_} foreach qw (id_user dt_start half_start dt_finish half_finish id_prestation_type);

			$_REQUEST {_cnt} = 1;

			do_update_prestations ();

			recalculate_prestations ();

			my $d = {
			
				id_prestation_type    => $_REQUEST {id_prestation_type},
				dt_start    => $_REQUEST {dt_start},
				half        => 0 + $_REQUEST {half_start},
				label_short => $prestation_type -> {label_short},
				color       => $prestation_type -> {prestation_type_group} -> {color},
				ids_users   => [$_REQUEST {id_user}, map {-1 * $_} @ids_rooms],
				no_href     => (!$prestation_type -> {length} && $prestation_type -> {is_half_hour} != -1) || $_REQUEST {id_user} < 0,
				id_user     => $_REQUEST {id_user},
				__last_scrollable_table_row     => $_REQUEST {__last_scrollable_table_row},
				__last_query_string => $_REQUEST {__last_query_string},
			
			};
			
			my $j = $_JSON -> encode ($d);
			
			my $s = "set_cell($j)";

			out_html ({}, $s);

		}

	}	

	};

#	sql_do ("UNLOCK TABLES");	
	
	if ($@) {
	
		my $m = $@;
		$m =~ s{^#.*?#:}{};
		$m =~ / at /;
		my $a = $_JSON -> encode ([$`]);
		out_html ({}, "var a = $a; alert (a[0]);");
	
	}
		
	return if $_REQUEST {__response_sent};
	
	my $h = {href => {action => ''}};
	
	check_href ($h);

	my $s = "nope('$h->{href}', '_self')";
			
	out_html ({}, $s);
			
}

################################################################################

sub do_update_prestations {

	my $lockfile = $r -> document_root . "/i/upload/images/$_REQUEST{id}.lock";

	trylock ($lockfile) or return;

	my $old_item = sql_select_hash ('prestations');
	
	sql_upload_file ({
		name             => 'file',
		table            => 'prestations',
		dir		         => 'upload/images',
		path_column      => 'file_path',
		type_column      => 'file_type',
		file_name_column => 'file_name',
		size_column      => 'file_size',
	});

	sql_do_update ('prestations', [qw(
		dt_start
		half_start
		dt_finish
		half_finish
		id_user
		id_users
		id_prestation_type
		note
		cnt
		id_prestation_partnership
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
				$h += int ($m / 60);
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
	
	unlock ($lockfile);	

}

################################################################################

sub validate_update_prestations {
	
	$_REQUEST {_id_prestation_type} or return "#_id_prestation_type#:Veuillez choisir le type de prestation";
	
	my $prestation_type = sql_select_hash ('prestation_types', $_REQUEST {_id_prestation_type});

	my $organisation = sql_select_hash ('organisations', $prestation_type -> {id_organisation});
	
	my $item = sql_select_hash ('prestations');

	unless ($prestation_type -> {is_multiday}) {
		my $field = $item -> {id_prestation_type} ? '' : '#_id_prestation_type#:';
		$_REQUEST {_dt_start}   eq $_REQUEST {_dt_finish} or return "${field}Ce type de prestation ne peut pas durer plusieurs jours";
		$_REQUEST {_half_start} == $_REQUEST {_half_finish} or return "${field}Ce type de prestation ne peut pas durer plusieurs demi-jours";
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
	
	
	my %holyday = ();
	
	sql_select_loop ('SELECT dt FROM holydays WHERE fake = 0 AND id_organisation = ? AND dt BETWEEN ? AND ?', sub {$holyday {$i -> {dt}} = 1}, $prestation_type -> {id_organisation}, $_REQUEST {_dt_start}, $_REQUEST {_dt_finish});

	my %workday = (map {$_ => 1} split /\D/, $organisation -> {days});
		
	my @days = ();
	
	my $day = $_REQUEST {_dt_start};

	while ($day le $_REQUEST {_dt_finish}) {
	
		my @day = split /-/, $day;
		
		$workday {Day_of_Week (@day)} or $holyday {$day} ||= 1;
		
		$holyday {$day} or push @days, $day;
		
		@day = Add_Delta_Days (@day, 1);
		
		$day = sprintf ('%04d-%02d-%02d', @day);
		
		if ($_USER -> {role} ne 'admin') {
		
			if (week_status (sprintf ('%02d/%02d/%02d', reverse @day)) != 2) {
			
				my @monday = Monday_of_Week (Week_of_Year (@day));
				
				my @sunday = Add_Delta_Days (@monday, 6);
			
				return sprintf ("#_dt_finish#: La semaine de \%02d/\%02d/\%04d � \%02d/\%02d/\%04d n'est pas encore publi�e", (reverse @monday), (reverse @sunday));
			
			}
		
		}
	
	}
	
	$_REQUEST {_cnt} = 0;
	
	my $start  = $_REQUEST {_dt_start}  . $_REQUEST {_half_start};
	my $finish = $_REQUEST {_dt_finish} . $_REQUEST {_half_finish};
	
	foreach my $day (@days) {
	
		foreach my $half (1, 2) {
		
			$day . $half ge $start  or next;
			$day . $half le $finish or next;
			
			$_REQUEST {_cnt} ++;
			
		}
	
	}
	
	my @id_users = grep {$_ > 0} grep {$_ != $_REQUEST {_id_user}} get_ids ('id_users');
	$_REQUEST {_id_users} = join ',', (-1, @id_users, -1);
		
	foreach my $id_user ($_REQUEST {_id_user}, @id_users) {
	
		next if $id_user <= 0;

		my $user = sql_select_hash ('users', $id_user);
		
		$prestation_type -> {ids_roles} =~ /\,$$user{id_role}\,/ or return "D�sol�, mais $$user{label} ne peut pas assister aux prestations $$prestation_type{label_short}.";
			
		0 == sql_select_scalar (<<EOS, $_REQUEST {id}, $user -> {id}, '%,' . $user -> {id} . ',%' , $_REQUEST {_dt_finish} . $_REQUEST {_half_finish}, $_REQUEST {_dt_start} . $_REQUEST {_half_start}, $_REQUEST {_dt_start}) or return "#_id_users_$$user{id}#:D�sol�, mais $$user{label} est occup� pendant cette p�riode.";
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
				AND dt_finish >= ?
			LIMIT
				1
EOS

	}
	
	my @id_prestations_rooms = sql_select_col ('SELECT id_room FROM prestations_rooms WHERE id_prestation = ? AND id_room > 0', $_REQUEST {id});
	
	if (@id_prestations_rooms) {
	
		my $ids = join ',', @id_prestations_rooms;
		
		my $conflict = sql_select_hash (<<EOS, $_REQUEST {_dt_finish} . $_REQUEST {_half_finish}, $_REQUEST {_dt_start} . $_REQUEST {_half_start}, $_REQUEST {_dt_start}, $_REQUEST {id});
			SELECT
				prestations_rooms.id
				, rooms.label
				, prestations_rooms.dt_start
				, prestations_rooms.dt_finish
			FROM
				prestations_rooms
				LEFT JOIN prestations ON prestations_rooms.id_prestation = prestations.id
				LEFT JOIN rooms ON prestations_rooms.id_room = rooms.id
			WHERE
				prestations_rooms.fake = 0
				AND prestations.fake = 0
				AND prestations_rooms.id_room IN ($ids)
				AND CONCAT(prestations_rooms.dt_start, prestations_rooms.half_start) <= ?
				AND CONCAT(prestations_rooms.dt_finish, prestations_rooms.half_finish) >= ?
				AND prestations_rooms.dt_finish >= ?
				AND prestations_rooms.id_prestation <> ?
			LIMIT
				1
EOS
	
		if ($conflict -> {id}) {
			__d ($conflict, 'dt_start', 'dt_finish');
			return "Conflit de r�servation pour $conflict->{label}";
		}
	
	}
	
	$_REQUEST {_id_prestation_partnership} = undef;
	
	if (exists $_REQUEST {_is_open}) {

		if ($_REQUEST {_is_open} < 2) {
		
			$_REQUEST {_ids_partners} = '';
			
		}
		else {
		
			my @ids = get_ids ('ids_partners');		
			@ids > 0 or return 'Vous avez oubli� de choisir les partenaires';
			$_REQUEST {_ids_partners} = join ',', (-1, (sort @ids), -1);
	
		}
		
		my $prestation_type = sql_select_hash (prestation_types => $_REQUEST {_id_prestation_type});
						
		if ($_REQUEST {_is_open} != $prestation_type -> {is_open}) {

			my $fixed_ids = join ',', (-1, (sort (grep {$_ > 0} split /\,/, $prestation_type -> {ids_partners})), -1);

			if ($fixed_ids ne $_REQUEST {_ids_partners}) {
			
				$_REQUEST {_id_prestation_partnership} = sql_select_id (prestation_partnerships => {
				
					fake					=> 0,
					id_organisation         => $prestation_type -> {id_organisation},
					ids_partners 			=> $_REQUEST {_ids_partners},
					is_open                 => $_REQUEST {_is_open},

				}, ['id_organisation', 'ids_partners', 'is_open']);

			}

		}
	
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
					is_placeable_by_conseiller IN (1, 3)
					OR ids_users LIKE '%,$$_USER{id},%'
					OR id=$$item{id_prestation_type}
EOS
			
		}
		else {

			$filter = <<EOS;
					(ids_users LIKE '%,$$_USER{id},%' AND is_placeable_by_conseiller <> 4)
					OR id=$$item{id_prestation_type}
EOS

		}
	
	}
	
	$filter = "($filter) AND id_organisation = $_USER->{id_organisation}";

	my $ids_groups = sql_select_ids ("SELECT id FROM groups WHERE id_organisation = ? AND fake = 0 AND (IFNULL(is_hidden, 0) = 0 OR id = ?)", $_USER -> {id_organisation}, 0 + $_USER -> {id_group});

	my @ids_users = (-1, grep {$_ > 0} ($item -> {id_user}, @{$item -> {id_users}}));
	
	my $ids_users = join ',', @ids_users;

	add_vocabularies ($item,
		users            => {filter => "((id in ($ids_users)) OR (id_group IN ($ids_groups) AND (dt_finish IS NULL OR dt_finish > '$item->{_dt_finish}')))"},
		prestation_types => {filter => $filter},
		organisations    => {filter => "CONCAT('-1,', ids_partners, '-1') LIKE ('%,$item->{prestation_type}->{id_organisation},%')"},
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
	
	if ($item -> {prestation_type} -> {is_half_hour} != 0) {
	
		foreach my $i (@{$item -> {inscriptions}}) {
			$i -> {id_user} or next;
			$item -> {no_move} = 1;
			last;
		}
	
	}
	
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
		
	my $partnership = $item -> {id_prestation_partnership} ?
	
		sql_select_hash ('SELECT * FROM prestation_partnerships WHERE id = ?', $item -> {id_prestation_partnership}) :
		
		$item -> {prestation_type};

	$item -> {is_open} = 0 + $partnership -> {is_open};

	$item -> {ids_partners} = [split /\,/, $partnership -> {ids_partners}];

	return $item;
	
}

################################################################################

sub select_prestations {
#my $time = time ();
#$time = __log_profilinig ($time, '      0');
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

    $_REQUEST {week} =~ /^[1-9]\d?$/ or delete $_REQUEST {year};

	$_REQUEST {week} = 1 if $_REQUEST {week} eq '0';
	
	unless ($_REQUEST {year}) {	
		($_REQUEST {week}, $_REQUEST {year}) = Week_of_Year (Today ());	
	}
		
	if ($_REQUEST {week} > Date::Calc::Weeks_in_Year ($_REQUEST {year})) {
		$_REQUEST {year} ++;
		$_REQUEST {week} = 1;
	}	
		
	my @monday = Monday_of_Week ($_REQUEST {week}, $_REQUEST {year});

	my $prev = [Week_of_Year (Add_Delta_Days (@monday, -7))];
	my $next = [Week_of_Year (Add_Delta_Days (@monday, 7))];
	
	my @days = ();
	
	my $ix_days = {};
	
	my $organisation = sql_select_hash (organisations => $_USER -> {id_organisation});
	
	$organisation -> {days} = [sort split ',', $organisation -> {days}];
		
	for (my $i = 0; $i < @{$organisation -> {days}}; $i++) {
	
		my $day_index = $organisation -> {days} -> [$i] - 1;
	
		my @day = Add_Delta_Days (@monday, $day_index);

		my $iso_dt = sprintf ('%04d-%02d-%02d', @day);
		my $fr_dt  = sprintf ('%02d/%02d/%04d', reverse @day);
	
		my $label = $day_names [$day_index] . '&nbsp;' . $day [2];
				
		push @days, {
			id => 2 * ($i + 1),
			iso_dt => $iso_dt,
			fr_dt => $fr_dt,
			label => $label,
			date  => [@day],
			half  => 1,
		};
		
		$ix_days -> {$iso_dt . '-' . 1} = $days [-1];
		
		if (@days > 1) {
			$days [-2] -> {next} = $days [-1];
		}

		push @days, {
			id => 2 * ($i + 1) + 1,
			iso_dt => $iso_dt,
			fr_dt => $fr_dt,
			label => $label,
			date  => [@day],
			half  => 2,
		};
				
		$ix_days -> {$iso_dt . '-' . 2} = $days [-1];

		$days [-2] -> {next} = $days [-1];
	
	}
	
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

	my $ids_partners = $organisation -> {ids_partners} || '-1';
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

	if ($week_status_type -> {id} != 1 || $_USER -> {role} eq 'admin') {
	
		$ids_partners .= ",$_USER->{id_organisation}";
	
	}
	
#$time = __log_profilinig ($time, '      3');

	my $prestations = $ids_partners eq '-1' ? [] :
		
		sql_select_all (<<EOS, $_REQUEST {year}, $_REQUEST {week});
			SELECT STRAIGHT_JOIN
				prestations.id
				, prestations.id_user
				, prestations.id_users
				, prestations.note
				, prestations.id_prestation_model
				, prestations.id_prestation_type
				, prestation_types.label_short AS label
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
				prestations_weeks.year = ?
				AND prestations_weeks.week = ?
				AND prestations_weeks.id_organisation IN ($ids_partners)
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
	
	if (!$_REQUEST {aliens} && !$item -> {inscription_to_clone} && !$item -> {prestation_to_clone}) {
	
		push @users, {label => 'Ressources'};
		push @users, @{ sql_select_all ("SELECT -id AS id, label FROM rooms WHERE fake = 0 $site_filter AND id_organisation = ? ORDER BY label", $_USER -> {id_organisation})};
	
	}
	
	$users = \@users;	

	my $prestations_rooms = [];

	if (!$_REQUEST {aliens} && ($week_status_type -> {id} != 1 || $_USER -> {role} eq 'admin')) {
								
		$prestations_rooms = sql_select_all (<<EOS, $_USER -> {id_organisation});
			SELECT
				prestations.id
				, prestations.note
				, - prestations_rooms.id_room AS id_user
				, prestation_types.label_short AS label
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
	
	my $off_periods = sql_select_all (<<EOS);
		SELECT
			off_periods.id
			, off_periods.id_user
			, IF(off_periods.dt_start  < '$dt_start',  '$dt_start',  off_periods.dt_start)    AS dt_start
			, IF(off_periods.dt_start  < '$dt_start',  1,            off_periods.half_start)  AS half_start
			, IF(off_periods.dt_finish > '$dt_finish', '$dt_finish', off_periods.dt_finish)   AS dt_finish
			, IF(off_periods.dt_finish > '$dt_finish', 2,            off_periods.half_finish) AS half_finish
		FROM
			off_periods
		WHERE
			off_periods.fake = 0
			AND off_periods.dt_start  <= '$dt_finish'
			AND off_periods.dt_finish >= '$dt_start'
			AND off_periods.id_user IN ($id_users)
EOS
#$time = __log_profilinig ($time, '      13');

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
#$time = __log_profilinig ($time, '      14');
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
#$time = __log_profilinig ($time, '      16');
	my $data = {
	
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

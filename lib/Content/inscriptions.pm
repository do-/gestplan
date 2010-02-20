
################################################################################

sub do_copy_from_inscriptions {

	my $item          = sql_select_hash (inscriptions);
	my $item_to_clone = sql_select_hash (inscriptions => $_REQUEST {_id_inscription_to_clone});
	
	foreach (qw(
		hour
		minute
	)) {
		delete $item_to_clone -> {$_}
	}
	
	foreach (qw(
		id
		id_prestation
		label
	)) {
		$item_to_clone -> {$_} = $item -> {$_};
	}
	
	sql_do ('DELETE FROM inscriptions WHERE id = ?', $item -> {id});
	
	sql_do_insert (inscriptions => $item_to_clone);
	
	sql_select_loop ('SELECT * FROM ext_field_values WHERE id_inscription = ?', sub {

		delete $i -> {id};
		$i -> {fake} = 0;
		$i -> {id_inscription} = $_REQUEST {id};
		
		sql_do_insert (ext_field_values => $i);

	}, $_REQUEST {_id_inscription_to_clone});

}

################################################################################

sub do_create_inscriptions {



	my $item = {};
	$item -> {prestation} = sql_select_hash ('prestations', $_REQUEST {id_prestation});
	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});
	
	my ($h, $m);

#	if ($item -> {prestation} -> {type} -> {is_half_hour} == -1) {
#		
#		($h, $m) = sql_select_array (<<EOS, $_REQUEST {id_prestation});
#			SELECT
#				hour_finish
#				, minute_finish
#			FROM
#				inscriptions
#			WHERE
#				id_prestation = ?
#				AND fake = 0
#			ORDER BY
#				hour_start DESC
#				, minute_start DESC
#			LIMIT
#				1
#EOS
#	
#	}
	
	$_REQUEST {id} = sql_do_insert ('inscriptions', {
		id_prestation  => $_REQUEST {id_prestation},
		id_author      => $_USER -> {id},
		hour_start     => $h,
		minute_start   => $m,		
	});
	


}

################################################################################

sub recalculate_inscriptions {

	my @today = Today ();
	
	my $data;

	if ($_REQUEST {id}) {

		$data = sql (inscriptions => $_REQUEST {id}, 'prestations(id_user, id_users, dt_start)', 'prestation_types(id_organisation)');
				
		$_REQUEST {__id_organisation} = $data -> {prestation_type} -> {id_organisation};

	}	
	
	send_refresh_messages ($_REQUEST {__id_organisation});
		
	$data -> {hour} or return;

	$_REQUEST {__old_hour} != $data -> {hour} or $_REQUEST {__old_minute} != $item -> {minute} or return;
	
	dt_iso (@today) eq $data -> {prestation} -> {dt_start} or return;

	my @ids_users = grep {$_ > 0 && $_ != $_USER -> {id}} ($data -> {prestation} -> {id_user}, split /\,/, $data -> {prestation} -> {id_users});
	
	@ids_users > 0 or return;
	
	my @js;
	
	$js [1] = "alert ('$data->{nom} $data->{prenom} est arrivé(e) à $data->{hour}h$data->{minute}.\\n'); try_to_reload (window._md5_refresh_local)";
	
	$js [0] = "showModalDialog ('/i/close.html?$_REQUEST{salt}', window); $js[1]";
	
	sql (users => [[id => \@ids_users]], sub {
	
		js_im (
		
			$i -> {id},
			
			$js [$i -> {no_popup}],
			
			{expires => [@today, 23, 59, 59]},
			
		);
	
	})

}

################################################################################

sub do_update_inscriptions {
		
	sql_do ('UPDATE ext_field_values SET fake = -1 WHERE id_inscription = ?', $_REQUEST {id});
	
	foreach my $key (keys %_REQUEST) {
	
		$key =~ /^_field_(\d+)$/ or next;
		
		my $id = sql_select_id (ext_field_values => {
			        	
			id_inscription => $_REQUEST {id},
			id_ext_field   => $1,
	
		}, ['id_inscription', 'id_ext_field']);
		
		my $ext_field_value = sql_select_hash (ext_field_values => $id);
		
		my $value = $_REQUEST {$key};
				
		if ($ext_field_value -> {file_name} && !$value) {
			
			sql_do ('UPDATE ext_field_values SET fake = 0 WHERE id = ?', $id);
			
		}
		else {
			
			if (length $value) {
				
				sql_do ('UPDATE ext_field_values SET value = ?, fake = 0 WHERE id = ?', $value, $id);
				
				sql_upload_file ({
					name             => "field_$1",
					table            => 'ext_field_values',
			 		id               => $id,
					dir		 		 => 'upload/images',
					path_column      => 'file_path',
					type_column      => 'file_type',
					file_name_column => 'file_name',
					size_column      => 'file_size',
				});
			
			}
			else {
			
				sql_do ('DELETE FROM ext_field_values WHERE id = ?', $id);
			
			}

		}

		delete $_REQUEST {$key};

	}

	sql_do ('DELETE FROM ext_field_values WHERE id_inscription = ? AND fake = -1', $_REQUEST {id});

	my $item = sql_select_hash ('inscriptions');
	
	$item -> {id_author} or sql_do ('UPDATE inscriptions SET id_author = ? WHERE id = ?', $_USER -> {id}, $item -> {id});
	
	$_REQUEST {__old_hour}   = $item -> {hour};
	$_REQUEST {__old_minute} = $item -> {minute};

	do_update_DEFAULT ();
		
}

################################################################################

sub do_mark_inscriptions {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
	
	$hour += $preconf -> {tz_shift};
	
	my $item = sql_select_hash ('inscriptions');
	
	if ($item -> {parent}) {
		$_REQUEST {id} = $item -> {parent};
		$item = sql_select_hash ('inscriptions');
	}
	
	my $id_inscriptions = sql_select_ids ('SELECT id FROM inscriptions WHERE parent = ?', $item -> {id});

	sql_select_loop (<<EOS, sub {sql_do ("UPDATE inscriptions SET hour = ?, minute = ?, id_user = ? WHERE id = ?", $hour, $min, $i -> {id_user}, $i -> {id})});
		SELECT
			inscriptions.id
			, prestations.id_user
		FROM
			inscriptions
			LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
		WHERE
			inscriptions.id IN ($_REQUEST{id},$id_inscriptions)
EOS
		
	esc ();
	
}

################################################################################

sub do_delete_inscriptions {
	
	my $item = sql_select_hash ('inscriptions');

	$item -> {prestation} = sql_select_hash ('prestations', $item -> {id_prestation});

	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});
	
	$item -> {prestation} -> {type} -> {ids_ext_fields} ||= -1;
	
	$_REQUEST {__id_organisation} = $item -> {prestation} -> {id_organisation};

	$item -> {ext_fields} = sql_select_all ("SELECT * FROM ext_fields WHERE fake = 0 AND id IN (" . $item -> {prestation} -> {type} -> {ids_ext_fields} . ") ORDER BY ord");
	
	my $fields = 'nom = NULL, prenom = NULL, id_user = NULL, hour = NULL, minute = NULL, id_author = NULL, fake = -1';
	
#	foreach my $field (@{$item -> {ext_fields}}) {
#		$fields .= ', field_' . $field -> {id} . ' = NULL';
#	}

	sql_do ("UPDATE inscriptions SET $fields WHERE id = ?", $_REQUEST {id});
	
	if (!$item -> {parent} && $item -> {id_author} == $_USER -> {id}) {
			
		my $ids = sql_select_ids ('SELECT id FROM inscriptions WHERE parent = ?', $item -> {id});
		
		$ids .= ",$item->{id}";
		
		sql_select_loop ("SELECT file_path FROM ext_field_values WHERE file_path IS NOT NULL AND id_inscription IN ($ids)", sub {
		
			unlink $r -> document_root . $i -> {file_path};
		
		});
			
		sql_do ("DELETE FROM ext_field_values WHERE id_inscription IN ($ids)");		
		
	}
	else {		
	
		sql_select_loop ("SELECT file_path FROM ext_field_values WHERE file_path IS NOT NULL AND id_inscription = ?", sub {
		
			unlink $r -> document_root . $i -> {file_path};
		
		}, $_REQUEST {id});

		sql_do ("DELETE FROM ext_field_values WHERE id_inscription = ?", $_REQUEST {id});

	}

	if ($item -> {prestation} -> {type} -> {is_half_hour} == -1) {
	
		my $prestation_invitation = sql_select_hash ('SELECT * FROM prestations_invitations WHERE id_prestation = ?', $item -> {prestation} -> {id});
		
		if (
			
			$prestation_invitation -> {id}
			
			&& $prestation_invitation -> {id_inscription} == $item -> {id}
			
			&& 0 == sql_select_scalar ('SELECT COUNT(*) FROM inscriptions WHERE fake = 0 AND id_prestation = ?', $item -> {prestation} -> {id})
				
		) {
			
			sql_do ('DELETE FROM prestations_invitations WHERE id = ?', $prestation_invitation -> {id});

			sql_do ('DELETE FROM inscriptions WHERE id_prestation = ?', $item -> {prestation} -> {id});

			sql_do ('DELETE FROM prestations  WHERE id            = ?', $item -> {prestation} -> {id});
			
		}
		elsif (!$item -> {parent} && $item -> {id_author} == $_USER -> {id}) {
								
			sql_do ('DELETE FROM inscriptions WHERE id     = ?', $item -> {id});
			
			my $ids = sql_select_ids (q {
			
				SELECT
					inscriptions.id_prestation
				FROM
					inscriptions
					LEFT JOIN prestations_invitations ON inscriptions.id_prestation = prestations_invitations.id_prestation
					LEFT JOIN inscriptions AS i ON (
						inscriptions.id_prestation = i.id_prestation
						AND inscriptions.id <> i.id
						AND i.fake = 0
					)
				WHERE
					inscriptions.parent = ?
					AND prestations_invitations.id > 0
				GROUP BY
					1
				HAVING
					COUNT(i.id) = 0
					
			}, $item -> {id});
			
			sql_do ("DELETE FROM prestations  WHERE id IN ($ids)");
			
			sql_do ('DELETE FROM inscriptions WHERE parent = ?', $item -> {id});
		
		}
		else {
		
			my $new_parent = sql_select_scalar ('SELECT MIN(id) FROM inscriptions WHERE parent = ?', $item -> {id});
			
			if ($new_parent) {
			
				sql_do ('UPDATE inscriptions SET parent = 0 WHERE     id = ?', $new_parent);
			
				sql_do ('UPDATE inscriptions SET parent = ? WHERE parent = ?', $new_parent, $item -> {id});
			
			}
	
			sql_do_delete ('inscriptions');

		}
		
	}
		
	delete $_REQUEST {id};

}

################################################################################

sub validate_update_inscriptions {
	
	my $item = sql_select_hash ('inscriptions');
	
	if ($_REQUEST {id_log} != $item -> {id_log}) {
	
		my $log  = sql_select_hash ('log',   $item -> {id_log});
		
		__d ($log, 'dt');
		
		my $user = sql_select_hash ('users', $log -> {id_user});
		
		return "Désolé, mais $user->{label} vient d'éditer cette fiche (à $log->{dt}). Veuillez cliquer 'retour'.";
	
	};
	
	delete $_REQUEST {id_log};
	
	$item -> {prestation} = sql_select_hash ('prestations', $item -> {id_prestation});
	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});

	if ($item -> {prestation} -> {type} -> {is_half_hour} == -1) {
	
		$_REQUEST {_hour_start}   > 0  or return "#_hour_start#:Vouz avez oublié indiquer l'heure du début";
		$_REQUEST {_hour_start}   < 23 or return "#_hour_start#:L'heure ne peut pas excéder 23";
		$_REQUEST {_minute_start} < 60 or return "#_minute_start#:Le nombre de minutes ne peut pas excéder 59";

		$_REQUEST {_hour_finish}   > 0  or return "#_hour_finish#:Vouz avez oublié indiquer l'heure de la fin";
		$_REQUEST {_hour_finish}   < 23 or return "#_hour_finish#:L'heure ne peut pas excéder 23";
		$_REQUEST {_minute_finish} < 60 or return "#_minute_finish#:Le nombre de minutes ne peut pas excéder 59";
		
		my $start  = 60 * $_REQUEST {_hour_start}  + $_REQUEST {_minute_start};
		my $finish = 60 * $_REQUEST {_hour_finish} + $_REQUEST {_minute_finish};
		
		$start < $finish or return "#_hour_finish#:Le début ne peut pas succéder à la fin";
		
		my $type       = $item -> {prestation} -> {type};
		my $half_start = $item -> {prestation} -> {half_start};
		
		my $h = $type -> {"half_${half_start}_h"};
		my $m = $type -> {"half_${half_start}_m"};
		
		$start >= 60 * $h + $m or return "#_hour_start#:Cette inscription ne peut débuter plus tôt que " . sprintf ('%02d:%02d', $h, $m);

		my $half_finish = $item -> {prestation} -> {half_finish};

		my $h = $type -> {"half_${half_finish}_to_h"};
		my $m = $type -> {"half_${half_finish}_to_m"};

		$finish <= 60 * $h + $m or return "#_hour_finish#:Cette inscription ne peut se terminer plus tard que " . sprintf ('%02d:%02d', $h, $m);

		$_REQUEST {_label} = sprintf ('%02d:%02d - %02d:%02d', $_REQUEST {_hour_start}, $_REQUEST {_minute_start}, $_REQUEST {_hour_finish}, $_REQUEST {_minute_finish});

		my $conflict = sql_select_hash (<<EOS, $item -> {id}, $item -> {id_prestation}, $finish, $start);
			SELECT
				*
		        FROM
		        	inscriptions
		        WHERE
		        	id <> ?
		        	AND id_prestation = ?
		        	AND fake = 0
		        	AND 60 * hour_start  + minute_start  <  ?
		        	AND 60 * hour_finish + minute_finish >  ?
		        LIMIT
		        	1
EOS

		!$conflict -> {id} || return "Cette inscripion est en conflit avec celle de $conflict->{label}";

	}

	$_REQUEST {_nom} or return "#_nom#:Vous avez oublié d'indiquer le nom";
	$_REQUEST {_prenom} or return "#_prenom#:Vous avez oublié d'indiquer le prénom";
		
#	if ($_REQUEST {_id_user}) {
#		$_REQUEST {_hour} > 0 or return "#_hour#:Ce(tte) jeune est reçu(e), donc il faut indiquer l'heure de son arrivée";
#	}

	$_REQUEST {_hour} > 0   or $_REQUEST {_hour}   = undef;
	$_REQUEST {_minute} > 0 or $_REQUEST {_minute} = undef;
	
	if ($_REQUEST {_hour} + $_REQUEST {_minute}) {
		$_REQUEST {_id_user} or return "#_hour#:Ce(tte) jeune est reçu(e), donc il faut indiquer la personne";
	}

	my $item = get_item_of_inscriptions ();
	
	foreach my $i (@{$item -> {ext_fields}}) {
		
		my $name = '_field_' . $i -> {id};

		if ($i -> {id_field_type} == 8) {

        	$_REQUEST {$name} = $_REQUEST {$name . ',-1'};
        	
        	$_REQUEST {$name} = '' if $_REQUEST {$name} eq '-1'

		}

		$i -> {is_mandatory} or next;

		my $vide = $i -> {id_field_type} == 1 ? '0' : '';
		
		$_REQUEST {$name} ne $vide or return "#$name#:Vous avez oublié de remplir le champ \"$i->{label}\"";
		
	}

	return undef;
	
}

################################################################################

sub get_item_of_inscriptions {

	my $item = sql_select_hash ('inscriptions');

	$item -> {id} or return esc ();
	
	foreach my $k (keys %$item) {$k =~ /^field_\d/ or next; delete $item -> {$k}};

	sql_select_loop ("SELECT * FROM ext_field_values WHERE id_inscription = ?", sub {
	
		$item -> {"field_$i->{id_ext_field}"} = $i -> {file_name} || $i -> {value};
		$item -> {"field_$i->{id_ext_field}_id"} = $i -> {id};
	
	}, $item -> {id});	
	
	$_REQUEST {id_log} = $item -> {id_log};
	
	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake});
	
	$item -> {author} = sql_select_hash ('users', $item -> {id_author});

	$item -> {prestation} = sql_select_hash ('prestations', $item -> {id_prestation});
	
	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});
	
	my ($y, $m, $d) = split /\-/, $item -> {prestation} -> {dt_start};
	$item -> {day} = Day_of_Week ($y, $m, $d);
	$item -> {day_name} = $day_names [$item -> {day} - 1];

### ok





	my ($dt_start, $dt_finish) = ($item -> {prestation} -> {dt_start}, $item -> {prestation} -> {dt_finish});

	__d ($item -> {prestation}, 'dt_start');

	$item -> {week_status_type} = sql_select_hash ('week_status_types', week_status ($item -> {prestation} -> {dt_start}, $_USER -> {id_organisation}));
	
	$item -> {read_only} = 1 if	$item -> {week_status_type} -> {id} == 3;
	
	if ($_USER -> {role} ne 'admin') {

		$item -> {read_only} ||= 1 if $item -> {week_status_type} -> {id} == 1;

		$item -> {read_only} ||= 1 if $item -> {prestation} -> {type} -> {is_protedted} && $item -> {id_author} && ($item -> {id_author} != $_USER -> {id});

	}
		
	$item -> {prestation} -> {user} = sql_select_hash ('users', $item -> {prestation} -> {id_user});
	
	$item -> {id_user} = $item -> {prestation} -> {id_user} if $_REQUEST {__edit};

	$item -> {ext_fields} = sql_select_all (qq{
		SELECT
			ext_fields.*
		FROM
			ext_fields
			LEFT JOIN prestation_types_ext_fields ON (
				prestation_types_ext_fields.id_ext_field = ext_fields.id
				AND prestation_types_ext_fields.id_prestation_type = ?
			)
		WHERE
			ext_fields.id IN ($item->{prestation}->{type}->{ids_ext_fields})
		ORDER BY
			IFNULL(prestation_types_ext_fields.ord, ext_fields.ord)
	}, $item -> {prestation} -> {type} -> {id});
	
	my $ids_groups = sql_select_ids ("SELECT id FROM groups WHERE id_organisation = ? AND fake = 0 AND IFNULL(is_hidden, 0) = 0", $item -> {prestation} -> {type} -> {id_organisation});
	$ids_groups .= ',';
	$ids_groups .= (0 + $_USER -> {id_group});

	my @vocs = ('users', {filter => "id_group IN ($ids_groups) AND IFNULL(dt_start, '$dt_finish') <= '$dt_finish' AND IFNULL(dt_finish, '$dt_start') >= '$dt_start' AND id_organisation=$item->{prestation}->{type}->{id_organisation}"});
	
	foreach my $field (@{$item -> {ext_fields}}) {
		
		$field -> {id_voc} or next;
		
		push @vocs, 'voc_' . $field -> {id_voc}, {order => 'ord'};
		
		if ($field -> {id_field_type} == 8) {

			$item -> {"field_$field->{id}"} = [split /,/, $item -> {"field_$field->{id}"}];

		}

	}
	
	$item -> {prestation} -> {id_users} ||= -1;

	add_vocabularies ($item, @vocs);

	$item -> {path} = [
		{
			type => 'prestations',
			id => $item -> {id_prestation},
			name =>
				$item -> {prestation} -> {type} -> {label} .
				' par ' .
				$item -> {prestation} -> {user} -> {label} .
				' le ' .
				$item -> {prestation} -> {dt_start} .
				($item -> {prestation} -> {half_start} == 1 ? ' matin' : ' après-midi')
				,
		},
		{type => 'inscriptions', name => $item -> {label}, id => $item -> {id}},
	];
	
	
	if ($item -> {prestation} -> {type} -> {is_half_hour} == -1) {
	
		$parent = {%$item};
		
		while ($parent -> {parent}) {
		
			$parent = sql_select_hash ('inscriptions', $parent -> {parent});
		
		}
		
		$item -> {inscriptions} = [
		
		    @{sql_select_all (<<EOS, $item -> {id}, $parent -> {id})},
			SELECT
				inscriptions.*
				, users.label AS user_label
			FROM
				inscriptions
				LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
				LEFT JOIN users ON prestations.id_user = users.id
			WHERE
				inscriptions.id <> ?
				AND (inscriptions.id = ?)
EOS

		    @{sql_select_all (<<EOS, $item -> {id}, $parent -> {id})},
			SELECT
				inscriptions.*
				, users.label AS user_label
			FROM
				inscriptions
				LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
				LEFT JOIN users ON prestations.id_user = users.id
			WHERE
				inscriptions.id <> ?
				AND (inscriptions.parent = ?)
EOS


		] if $parent -> {id};

	
	}
	else {
		
		$item -> {inscriptions} = [];
		
	}
	
	if ($item -> {is_unseen}) {
		sql_do ('UPDATE inscriptions SET is_unseen = 0 WHERE id = ?', $item -> {id});
	}

	$item -> {prestation_type_files} = sql_select_all (<<EOS, $item -> {prestation} -> {id_prestation_type});
		SELECT
			prestation_type_files.*
		FROM
			prestation_type_files
		WHERE
			prestation_type_files.fake = 0			
			AND prestation_type_files.id_prestation_type = ?
		ORDER BY
			prestation_type_files.label
EOS

	$item -> {inscriptions} = sql_select_all (<<EOS, $item -> {id_prestation});
		SELECT
			inscriptions.*
		FROM
			inscriptions
		WHERE
			id_prestation = ?
			AND inscriptions.fake <= 0
		ORDER BY
			hour_start
			, minute_start
			, id
EOS

	if ($item -> {prestation} -> {type} -> {id_organisation} != $_USER -> {id_organisation}) {
	
		$inscriptions = [grep {$_ -> {id_organisation} == $_USER -> {id_organisation}} @$inscriptions];
		
	}

	($item -> {prev}, $item -> {next}) = prev_next_n ($item, $item -> {inscriptions});

	return $item;

}

################################################################################

sub select_inscriptions {

#	$_REQUEST {__meta_refresh} = $_USER -> {refresh_period} || 300;

	$_REQUEST {id_user} ||= $_USER -> {id};
	$_REQUEST {id_day_period} ||= 3;
	
	my $user = sql_select_hash ('users', $_REQUEST {id_user});
	
	$_REQUEST {dt} ||= sprintf ('%02d/%02d/%04d', reverse Today ());
	
	my ($y, $m, $d) = reverse split /\//, $_REQUEST {dt};
	$_REQUEST {_day_name} = $day_names [Day_of_Week ($y, $m, $d) - 1];
	
	my $organisation = sql_select_hash (organisations => $_USER -> {id_organisation});
	
	foreach (split /\,/, $organisation -> {days}) { $organisation -> {days} -> {$_} = 1}

	my $prevnext = {

		-1 => {
			type => 'button',
			icon => 'left',
		},

		1 => {
			type => 'button',
			icon => 'right',
		},

	};
	
	foreach my $dir (-1, 1) {

		my @day = ($y, $m, $d);
	
		while (1) {
		
			@day = Add_Delta_Days (@day, $dir);
			
			$organisation -> {days} -> {Day_of_Week (@day)} or next;
			
			my $dt = sprintf ('%02d/%02d/%04d', reverse @day);
			
			$prevnext -> {$dir} -> {label} = $dt;
			$prevnext -> {$dir} -> {href}  = {dt => $dt};
			
			last;
		
		}

	}
	
	






	
	my $week_status_type = sql_select_hash ('week_status_types', week_status ($_REQUEST {dt}, $user -> {id_organisation}));

 	if ($week_status_type -> {id} == 1 && $_USER -> {role} ne 'admin') {
 		return return_md5_checked ({
			prestation_1 => {},
			prestation_2 => {},
			week_status_type => $week_status_type,
			users => sql_select_vocabulary ('users', {filter => 'id_group > 0 AND id_organisation = ' . $_USER -> {id_organisation}}),
		});
	}
	
	my $dt = $_REQUEST {dt};
	
	$dt =~ s{(\d\d)\/(\d\d)\/(\d\d\d\d)}{$3-$2-$1};	

	($_REQUEST {_week}, $_REQUEST {_year}) = Week_of_Year ($3, $2, $1);	
	
	my $id_absent_users_1 = -1;
	my $id_absent_users_2 = -1;
	
	sql_select_loop (
	
		'SELECT * FROM off_periods WHERE dt_start <= ? AND dt_finish >= ? AND fake = 0',
		
		sub {
		
			if ("$i->{dt_start} $i->{half_start}" le "$dt 1") {
			
				$id_absent_users_1 .= ",$i->{id_user}";
			
			}
		
			if ("$i->{dt_finish} $i->{half_finish}" ge "$dt 2") {
			
				$id_absent_users_2 .= ",$i->{id_user}";
			
			}

		},
		
		$dt,
		
		$dt,
		
	);
	
#	my $id_absent_users = sql_select_ids ('SELECT id_user FROM off_periods WHERE dt_start <= ? AND dt_finish >= ? AND fake = 0', $dt, $dt);

	my $prestation_1 = sql_select_hash (<<EOS, $_REQUEST {id_user}, '%,' . $_REQUEST {id_user} . ',%', $dt . 1, $dt . 1);
		SELECT
			prestations.*
			, prestation_types.id_organisation
			, sites.label AS site_label
		FROM
			prestations
			LEFT JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
			LEFT JOIN sites ON prestations.id_site = sites.id
		WHERE
			(prestations.id_user = ? OR prestations.id_users LIKE ?)
			AND CONCAT(prestations.dt_start,  prestations.half_start)  <= ?
			AND CONCAT(prestations.dt_finish, prestations.half_finish) >= ?
			and prestations.fake = 0
EOS
	
	my %cache = ();
	
	if ($prestation_1 -> {id}) {
	
		my ($week, $year) = Week_of_Year (dt_y_m_d ($prestation_1 -> {dt_start}));
		
		$prestation_1 -> {clone_href} = "/?type=prestations&year=$year&week=$week&id_prestation_to_clone=$prestation_1->{id}",
	
		$prestation_1 -> {type} = sql_select_hash ('prestation_types', $prestation_1 -> {id_prestation_type});
		
		$prestation_1 -> {read_only} =
			$_USER -> {role} ne 'admin'
			&& $prestation_1 -> {type} -> {is_private}
			&& $prestation_1 -> {id_user} != $_USER -> {id}
			&& $prestation_1 -> {id_users} !~ /,$$_USER{id},/
#			&& $prestation_1 -> {type} -> {ids_roles} !~ /,$$_USER{id_role},/
			;
			
		my $id_users = join ',', grep {$_ > 0} ($prestation_1 -> {id_users}, $prestation_1 -> {id_user});						
		$prestation_1 -> {present_users} = sql_select_scalar ("SELECT COUNT(*) FROM users WHERE id IN ($id_users) AND id NOT IN ($id_absent_users_1)");
		
		$prestation_1 -> {ext_fields} = sql_select_all (<<EOS,  $prestation_1 -> {type} -> {id});
			SELECT
				prestation_types_ext_fields.*
				, ext_fields.*
				, ext_fields.id AS id_ext_field
			FROM
				ext_fields
				LEFT JOIN prestation_types_ext_fields ON (prestation_types_ext_fields.id_ext_field = ext_fields.id AND prestation_types_ext_fields.id_prestation_type = ?)
			WHERE
				ext_fields.id IN ($prestation_1->{type}->{ids_ext_fields})
			ORDER BY
				IFNULL(prestation_types_ext_fields.ord, ext_fields.ord)
EOS

		$prestation_1 -> {inscriptions} = sql_select_all (<<EOS, $prestation_1 -> {id});
			SELECT
				inscriptions.*
				, users.id_organisation
				, reception.label AS recu_par
			FROM
				inscriptions
				LEFT JOIN users ON inscriptions.id_author = users.id
				LEFT JOIN users AS reception ON inscriptions.id_user = reception.id
			WHERE
				id_prestation = ?
				AND inscriptions.fake <= 0
			ORDER BY
				hour_start
				, minute_start
				, id
EOS

		my ($ids, $idx) = ids ($prestation_1 -> {inscriptions});
	
		sql_select_loop ("SELECT * FROM ext_field_values WHERE id_inscription IN ($ids)", sub {
		
			$idx -> {$i -> {id_inscription}} -> {"field_$i->{id_ext_field}"} = $i -> {file_name} || $i -> {value};
			$idx -> {$i -> {id_inscription}} -> {"field_$i->{id_ext_field}_id"} = $i -> {id};
		
		});

		foreach my $field (@{$prestation_1 -> {ext_fields}}) {
		
			my $key = 'field_' . $field -> {id_ext_field};
		
			if ($field -> {id_field_type} == 1) {
			
				my $table = $field -> {id_voc} ? 'voc_' . $field -> {id_voc} : 'users';
							
				foreach my $i (@{$prestation_1 -> {inscriptions}}) {

					next if $i -> {fake};

					$i -> {$key} = ($cache {"${table}_$i->{$key}"} ||= sql_select_scalar ("SELECT label FROM $table WHERE id = ?", $i -> {$key}));

				}
				
			}			
			elsif ($field -> {id_field_type} == 8) {
			
				my $table = $field -> {id_voc} ? 'voc_' . $field -> {id_voc} : 'users';
							
				foreach my $i (@{$prestation_1 -> {inscriptions}}) {

					next if $i -> {fake};

					$i -> {$key} =
						
						join ', ',
						
							sort grep {$_} map {
							
								$cache {"${table}_$_"} ||=
								
								sql_select_scalar ("SELECT label FROM $table WHERE id = ?", $_)
							
							}
							
								split /\,/, $i -> {$key}

				}
				
			}			
			elsif ($field -> {id_field_type} == 4) {
			
				foreach my $i (@{$prestation_1 -> {inscriptions}}) {
					next if $i -> {fake};
					defined $i -> {$key} or next;
					$i -> {$key} = $i -> {$key} ? 'Oui' : 'Non';
				}
				
			}			
			elsif ($field -> {id_field_type} == 7) {
			
				foreach my $i (@{$prestation_1 -> {inscriptions}}) {
					next if $i -> {fake};
					$i -> {$key} = $i -> {$key} ? 'Oui' : 'Non';
				}
				
			}			
			
		}
		
	}

	my $prestation_2 = sql_select_hash (<<EOS, $_REQUEST {id_user}, '%,' . $_REQUEST {id_user} . ',%', $dt . 2, $dt . 2);
		SELECT
			prestations.*
			, prestation_types.id_organisation
			, sites.label AS site_label
		FROM
			prestations
			LEFT JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
			LEFT JOIN sites ON prestations.id_site = sites.id
		WHERE
			(prestations.id_user = ? OR prestations.id_users LIKE ?)
			AND CONCAT(prestations.dt_start,  prestations.half_start)  <= ?
			AND CONCAT(prestations.dt_finish, prestations.half_finish) >= ?
			and prestations.fake = 0
EOS




	if ($prestation_2 -> {id}) {

		my ($week, $year) = Week_of_Year (dt_y_m_d ($prestation_2 -> {dt_start}));
		
		$prestation_2 -> {clone_href} = "/?type=prestations&year=$year&week=$week&id_prestation_to_clone=$prestation_2->{id}",

		$prestation_2 -> {type} = sql_select_hash ('prestation_types', $prestation_2 -> {id_prestation_type});	
   	
		$prestation_2 -> {read_only} =
			$_USER -> {role} ne 'admin'
			&& $prestation_2 -> {type} -> {is_private}
			&& $prestation_2 -> {id_user} != $_USER -> {id}
			&& $prestation_2 -> {id_users} !~ /,$$_USER{id},/
#			&& $prestation_2 -> {type} -> {ids_roles} !~ /,$$_USER{id_role},/
			;

		my $id_users = join ',', grep {$_ > 0} ($prestation_2 -> {id_users}, $prestation_2 -> {id_user});						
		$prestation_2 -> {present_users} = sql_select_scalar ("SELECT COUNT(*) FROM users WHERE id IN ($id_users) AND id NOT IN ($id_absent_users_2)");

		$prestation_2 -> {ext_fields} = sql_select_all (<<EOS,  $prestation_2 -> {type} -> {id});
			SELECT
				prestation_types_ext_fields.*
				, ext_fields.*
				, ext_fields.id AS id_ext_field
			FROM
				ext_fields
				LEFT JOIN prestation_types_ext_fields ON (prestation_types_ext_fields.id_ext_field = ext_fields.id AND prestation_types_ext_fields.id_prestation_type = ?)
			WHERE
				ext_fields.id IN ($prestation_2->{type}->{ids_ext_fields})
			ORDER BY
				IFNULL(prestation_types_ext_fields.ord, ext_fields.ord)
EOS

		$prestation_2 -> {inscriptions} = sql_select_all (<<EOS, $prestation_2 -> {id});
			SELECT
				inscriptions.*
				, users.id_organisation
				, reception.label AS recu_par
			FROM
				inscriptions
				LEFT JOIN users ON inscriptions.id_author = users.id
				LEFT JOIN users AS reception ON inscriptions.id_user = reception.id
			WHERE
				id_prestation = ?
				AND inscriptions.fake <= 0
			ORDER BY
				hour_start
				, minute_start
				, id
EOS
		
		my ($ids, $idx) = ids ($prestation_2 -> {inscriptions});
	
		sql_select_loop ("SELECT * FROM ext_field_values WHERE id_inscription IN ($ids)", sub {
		
			$idx -> {$i -> {id_inscription}} -> {"field_$i->{id_ext_field}"} = $i -> {file_name} || $i -> {value};
			$idx -> {$i -> {id_inscription}} -> {"field_$i->{id_ext_field}_id"} = $i -> {id};
		
		});

		foreach my $field (@{$prestation_2 -> {ext_fields}}) {
		
			my $key = 'field_' . $field -> {id_ext_field};
		
			if ($field -> {id_field_type} == 1) {
			
				my $table = $field -> {id_voc} ? 'voc_' . $field -> {id_voc} : 'users';
							
				foreach my $i (@{$prestation_2 -> {inscriptions}}) {

					next if $i -> {fake};

					$i -> {$key} = ($cache {"${table}_$i->{$key}"} ||= sql_select_scalar ("SELECT label FROM $table WHERE id = ?", $i -> {$key}));

				}
				
			}			
			elsif ($field -> {id_field_type} == 8) {
			
				my $table = $field -> {id_voc} ? 'voc_' . $field -> {id_voc} : 'users';
							
				foreach my $i (@{$prestation_2 -> {inscriptions}}) {

					next if $i -> {fake};

					$i -> {$key} =
						
						join ', ',
						
							sort grep {$_} map {
							
								$cache {"${table}_$_"} ||=
								
								sql_select_scalar ("SELECT label FROM $table WHERE id = ?", $_)
							
							}
							
								split /\,/, $i -> {$key}

				}
				
			}			
			elsif ($field -> {id_field_type} == 4) {
			
				foreach my $i (@{$prestation_2 -> {inscriptions}}) {
					next if $i -> {fake};
					defined $i -> {$key} or next;
					$i -> {$key} = $i -> {$key} ? 'Oui' : 'Non';
				}
				
			}			
			elsif ($field -> {id_field_type} == 7) {
			
				foreach my $i (@{$prestation_2 -> {inscriptions}}) {
					next if $i -> {fake};
					$i -> {$key} = $i -> {$key} ? 'Oui' : 'Non';
				}
				
			}			
			
		}

	}

	return_md5_checked {
		id_absent_users => $id_absent_users,
		prestation_1 => $prestation_1,
		prestation_2 => $prestation_2,
		week_status_type => $week_status_type,
		users => sql_select_vocabulary ('users', {filter => 'id_group > 0 AND id_organisation = ' . $_USER -> {id_organisation}}),
		day_periods => sql_select_vocabulary ('day_periods'),
		user => $user,
		prevnext => $_REQUEST {id_inscription_to_clone} ? {} : $prevnext,
	};
	
}

1;

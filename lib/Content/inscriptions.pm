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

sub _refresh_alerts {

	my $dead_ids = sql_select_ids (<<EOS, sprintf ('%04d-%02d-%02d', Today ()));
		SELECT
			alerts.id
		FROM
			alerts
			INNER JOIN inscriptions ON alerts.id_inscription = inscriptions.id
			INNER JOIN prestations  ON inscriptions.id_prestation = prestations.id
		WHERE
			prestations.dt_start < ?
EOS
	
	sql_do ("DELETE FROM alerts WHERE id IN ($dead_ids)");

	my $item = sql_select_hash ('inscriptions');

	my $prestation = sql_select_hash ('prestations', $item -> {id_prestation});

	foreach my $id_user (grep {$_ > 0 && $_ != $_USER -> {id}} ($prestation -> {id_user}, split /\,/, $prestation -> {id_users})) {
		
		sql_do_insert ('alerts', {
			fake    => 0,
			id_user => $id_user,
			id_inscription => $_REQUEST {id},
		});
		
	}

}

################################################################################

sub do_update_inscriptions {
	
	do_update_DEFAULT ();
	
	$_REQUEST {_hour} or return;
	
	_refresh_alerts ();

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
	
	_refresh_alerts ();
	
	esc ();
	
}

################################################################################

sub do_delete_inscriptions {
	
	my $item = sql_select_hash ('inscriptions');

	$item -> {prestation} = sql_select_hash ('prestations', $item -> {id_prestation});

	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});

	$item -> {ext_fields} = sql_select_all ("SELECT * FROM ext_fields WHERE fake = 0 AND id IN (" . $item -> {prestation} -> {type} -> {ids_ext_fields} . ") ORDER BY ord");
	
	my $fields = 'nom = NULL, prenom = NULL, id_user = NULL, hour = NULL, minute = NULL, fake = -1';
	
	foreach my $field (@{$item -> {ext_fields}}) {
		$fields .= ', field_' . $field -> {id} . ' = NULL';
	}

	sql_do ("UPDATE inscriptions SET $fields WHERE id = ?", $_REQUEST {id});
	
	if ($item -> {prestation} -> {type} -> {is_half_hour} == -1) {
	
		if (!$item -> {parent} && $item -> {id_author} == $_USER -> {id}) {
		
			sql_do ('DELETE FROM inscriptions WHERE id = ? OR parent = ?', $item -> {id}, $item -> {id});
		
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

	my $item = sql_select_hash ('inscriptions');

	if ($_REQUEST {id_log} != $item -> {id_log}) {
	
		my $log  = sql_select_hash ('log',   $item -> {id_log});
		
		__d ($log, 'dt');
		
		my $user = sql_select_hash ('users', $log -> {id_user});
		
		return "Désolé, mais $user->{label} vient d'éditer cette fiche (à $log->{dt}). Veuillez cliquer 'retour'.";
	
	};
	
	delete $_REQUEST {id_log};

	return undef;
	
}

################################################################################

sub get_item_of_inscriptions {

	my $item = sql_select_hash ('inscriptions');
	
	$_REQUEST {id_log} = $item -> {id_log};
	
	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake});
	
	$item -> {prestation} = sql_select_hash ('prestations', $item -> {id_prestation});
	
	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});
	
	my ($y, $m, $d) = split /\-/, $item -> {prestation} -> {dt_start};
	$item -> {day} = Day_of_Week ($y, $m, $d);
	$item -> {day_name} = $day_names [$item -> {day} - 1];

	__d ($item -> {prestation}, 'dt_start');

	$item -> {week_status_type} = sql_select_hash ('week_status_types', week_status ($item -> {prestation} -> {dt_start}, $_USER -> {id_organisation}));
	
	$item -> {read_only} = $item -> {week_status_type} -> {id} == 3 || ($item -> {week_status_type} -> {id} == 1 && $_USER -> {role} ne 'admin');
	
	$item -> {prestation} -> {user} = sql_select_hash ('users', $item -> {prestation} -> {id_user});
	
	$item -> {id_user} = $item -> {prestation} -> {id_user} if $_REQUEST {__edit};

	$item -> {ext_fields} = sql_select_all ("SELECT * FROM ext_fields WHERE fake = 0 AND id IN (" . $item -> {prestation} -> {type} -> {ids_ext_fields} . ") ORDER BY ord");
	
	my @vocs = ('users', {filter => 'id_group > 0 AND id_organisation = ' . $item -> {prestation} -> {type} -> {id_organisation}});
	
	foreach my $field (@{$item -> {ext_fields}}) {
		
		$field -> {id_voc} or next;
		
		push @vocs, 'voc_' . $field -> {id_voc}, {order => 'ord'};
		
	}
	
	$item -> {prestation} -> {id_users} ||= -1;

	add_vocabularies ($item, @vocs);

	$item -> {path} = [
		{
			type => 'inscriptions',
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
		
		$item -> {inscriptions} = sql_select_all (<<EOS, $item -> {id}, $parent -> {id}, $parent -> {id});
			SELECT
				inscriptions.*
				, users.label AS user_label
			FROM
				inscriptions
				LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
				LEFT JOIN users ON prestations.id_user = users.id
			WHERE
				inscriptions.id <> ?
				AND (inscriptions.id = ? OR inscriptions.parent = ?)
EOS
	
	}
	else {
		
		$item -> {inscriptions} = [];
		
	}
	
	if ($item -> {is_unseen}) {
		sql_do ('UPDATE inscriptions SET is_unseen = 0 WHERE id = ?', $item -> {id});
	}

	return $item;

}

################################################################################

sub select_inscriptions {

	$_REQUEST {__meta_refresh} = $_USER -> {refresh_period} || 300;

	$_REQUEST {id_user} ||= $_USER -> {id};
	$_REQUEST {id_day_period} ||= 3;
	
	my $user = sql_select_hash ('users', $_REQUEST {id_user});
	
	$_REQUEST {dt} ||= sprintf ('%02d/%02d/%04d', reverse Today ());
	
	my ($y, $m, $d) = reverse split /\//, $_REQUEST {dt};
	$_REQUEST {_day_name} = $day_names [Day_of_Week ($y, $m, $d) - 1];
	
	my $week_status_type = sql_select_hash ('week_status_types', week_status ($_REQUEST {dt}, $user -> {id_organisation}));

 	if ($week_status_type -> {id} == 1 && $_USER -> {role} ne 'admin') {
 		return {
			prestation_1 => {},
			prestation_2 => {},
			week_status_type => $week_status_type,
			users => sql_select_vocabulary ('users', {filter => 'id_group > 0 AND id_organisation = ' . $_USER -> {id_organisation}}),
		};
	}
	
	my $dt = $_REQUEST {dt};
	
	$dt =~ s{(\d\d)\/(\d\d)\/(\d\d\d\d)}{$3-$2-$1};	

	($_REQUEST {_week}, $_REQUEST {_year}) = Week_of_Year ($3, $2, $1);	
	
	my $id_absent_users = sql_select_ids ('SELECT id_user FROM off_periods WHERE dt_start <= ? AND dt_finish >= ? AND fake = 0', $dt, $dt);

	my $prestation_1 = sql_select_hash (<<EOS, $_REQUEST {id_user}, '%,' . $_REQUEST {id_user} . ',%', $dt . 1, $dt . 1);
		SELECT
			*
		FROM
			prestations
		WHERE
			(prestations.id_user = ? OR prestations.id_users LIKE ?)
			AND CONCAT(prestations.dt_start,  prestations.half_start)  <= ?
			AND CONCAT(prestations.dt_finish, prestations.half_finish) >= ?
			and fake = 0
EOS
	
	if ($prestation_1 -> {id}) {
	
		$prestation_1 -> {type} = sql_select_hash ('prestation_types', $prestation_1 -> {id_prestation_type});
		
		$prestation_1 -> {read_only} =
			$_USER -> {role} ne 'admin'
			&& $prestation_1 -> {type} -> {is_private}
			&& $prestation_1 -> {id_user} != $_USER -> {id}
			&& $prestation_1 -> {id_users} !~ /,$$_USER{id},/
#			&& $prestation_1 -> {type} -> {ids_roles} !~ /,$$_USER{id_role},/
			;
			
		my $id_users = join ',', grep {$_} ($prestation_1 -> {id_users}, $prestation_1 -> {id_user});						
		$prestation_1 -> {present_users} = sql_select_scalar ("SELECT COUNT(*) FROM users WHERE id IN ($id_users) AND id NOT IN ($id_absent_users)");
		
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

		$prestation_1 -> {inscriptions} = sql_select_all ('SELECT * FROM inscriptions WHERE id_prestation = ? AND fake <= 0 ORDER BY hour_start, minute_start, id', $prestation_1 -> {id});

		foreach my $field (@{$prestation_1 -> {ext_fields}}) {
		
			if ($field -> {id_field_type} == 1) {
			
				my $table = $field -> {id_voc} ? 'voc_' . $field -> {id_voc} : 'users';
							
				foreach my $i (@{$prestation_1 -> {inscriptions}}) {
					next if $i -> {fake};
					$i -> {'field_' . $field -> {id_ext_field}} = sql_select_scalar ("SELECT label FROM $table WHERE id = ?", $i -> {'field_' . $field -> {id_ext_field}});
				}
				
			}			
			elsif ($field -> {id_field_type} == 4) {
			
				foreach my $i (@{$prestation_1 -> {inscriptions}}) {
					next if $i -> {fake};
					$i -> {'field_' . $field -> {id_ext_field}} = $i -> {'field_' . $field -> {id_ext_field}} ? 'Oui' : 'Non';
				}
				
			}			
			
		}
		
		if ($prestation_1 -> {note}) {
		
		    unshift @{$prestation_1 -> {inscriptions}}, {
		    	id => -1,
		    	label => $prestation_1 -> {note},
		    	is_note => 1,
			}
			
		}		
		
	}

	my $prestation_2 = sql_select_hash (<<EOS, $_REQUEST {id_user}, '%,' . $_REQUEST {id_user} . ',%', $dt . 2, $dt . 2);
		SELECT
			*
		FROM
			prestations
		WHERE
			(prestations.id_user = ? OR prestations.id_users LIKE ?)
			AND CONCAT(prestations.dt_start,  prestations.half_start)  <= ?
			AND CONCAT(prestations.dt_finish, prestations.half_finish) >= ?
			and fake = 0
EOS

	if ($prestation_2 -> {id}) {

		$prestation_2 -> {type} = sql_select_hash ('prestation_types', $prestation_2 -> {id_prestation_type});	
   	
		$prestation_2 -> {read_only} =
			$_USER -> {role} ne 'admin'
			&& $prestation_2 -> {type} -> {is_private}
			&& $prestation_2 -> {id_user} != $_USER -> {id}
			&& $prestation_2 -> {id_users} !~ /,$$_USER{id},/
#			&& $prestation_2 -> {type} -> {ids_roles} !~ /,$$_USER{id_role},/
			;

		my $id_users = join ',', grep {$_} ($prestation_2 -> {id_users}, $prestation_2 -> {id_user});						
		$prestation_2 -> {present_users} = sql_select_scalar ("SELECT COUNT(*) FROM users WHERE id IN ($id_users) AND id NOT IN ($id_absent_users)");

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

		$prestation_2 -> {inscriptions} = sql_select_all ('SELECT * FROM inscriptions WHERE id_prestation = ? AND fake <= 0 ORDER BY hour_start, minute_start, id', $prestation_2 -> {id});
		
		foreach my $field (@{$prestation_2 -> {ext_fields}}) {
		
			if ($field -> {id_field_type} == 1) {
			
				my $table = $field -> {id_voc} ? 'voc_' . $field -> {id_voc} : 'users';
							
				foreach my $i (@{$prestation_2 -> {inscriptions}}) {
					next if $i -> {fake};
					$i -> {'field_' . $field -> {id_ext_field}} = sql_select_scalar ("SELECT label FROM $table WHERE id = ?", $i -> {'field_' . $field -> {id_ext_field}});
				}
				
			}			
			elsif ($field -> {id_field_type} == 4) {
			
				foreach my $i (@{$prestation_2 -> {inscriptions}}) {
					next if $i -> {fake};
					$i -> {'field_' . $field -> {id_ext_field}} = $i -> {'field_' . $field -> {id_ext_field}} ? 'Oui' : 'Non';
				}
				
			}			
			
		}

		if ($prestation_2 -> {note}) {
		
		    unshift @{$prestation_2 -> {inscriptions}}, {
		    	id => -1,
		    	label => $prestation_2 -> {note},
		    	is_note => 1,
			}
			
		}		

	}

	return {
		id_absent_users => $id_absent_users,
		prestation_1 => $prestation_1,
		prestation_2 => $prestation_2,
		week_status_type => $week_status_type,
		users => sql_select_vocabulary ('users', {filter => 'id_group > 0 AND id_organisation = ' . $_USER -> {id_organisation}}),
		day_periods => sql_select_vocabulary ('day_periods'),
		user => $user,
	};
	
}

1;

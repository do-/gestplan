################################################################################

sub recalculate_inscriptions_select {

	send_refresh_messages ();

}

################################################################################

sub do_add_inscriptions_select {

	my $item = sql_select_hash ('inscriptions');

	$item -> {parent}    = $item -> {id};
	delete                 $item -> {id};
	$item -> {fake}      = 0;
	$item -> {is_unseen} = 1;

	my $prestation = sql_select_hash ('prestations', $item -> {id_prestation});
	delete $prestation -> {id};
	$prestation -> {fake} = 0;
	
	@ids_prestations = get_ids ('prestation');

	foreach my $id_user (get_ids ('user')) {
        	$prestation -> {id_user} = $id_user;
		push @ids_prestations, sql_do_insert ('prestations', $prestation);
	}

	foreach my $id_prestation (@ids_prestations) {
		delete $item -> {id};
        	$item -> {id_prestation} = $id_prestation;
		sql_do_insert ('inscriptions', $item);
	}
	
	my $id_inscriptions = sql_select_ids ('SELECT id FROM inscriptions WHERE parent = ?', $item -> {parent});
	
	$id_inscriptions =
	
		sql_select_ids (<<EOS, $item -> {parent}, $_USER -> {id})
			SELECT
				inscriptions.id
			FROM
				inscriptions
				LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
			WHERE
				inscriptions.id = ?
				AND prestations.id_user = ?
EOS

		. ',' .
	
		sql_select_ids (<<EOS, $item -> {parent}, $_USER -> {id});
			SELECT
				inscriptions.id
			FROM
				inscriptions
				LEFT JOIN prestations ON inscriptions.id_prestation = prestations.id
			WHERE
				inscriptions.parent = ?
				AND prestations.id_user = ?
EOS

	sql_do ("UPDATE inscriptions SET is_unseen = 0 WHERE id IN ($id_inscriptions)");

	esc ();

}

################################################################################

sub validate_add_inscriptions_select {

	@u = get_ids ('user');
	@p = get_ids ('prestation');
		
	@u + @p > 0 or return "Vous n'avez sélectionné personne";

	return undef;
	
}

################################################################################

sub get_item_of_inscriptions_select {

	my $item = sql_select_hash ('inscriptions');
	
foreach my $k (keys %$item) {$k =~ /^field_\d/ or next; delete $item -> {$k}};

	sql_select_loop ("SELECT * FROM ext_field_values WHERE id_inscription = ?", sub {
	
		$item -> {"field_$i->{id_ext_field}"} = $i -> {value};
	
	}, $item -> {id});

	$_REQUEST {__read_only} = 1;
	
	$item -> {prestation} = sql_select_hash ('prestations', $item -> {id_prestation});
	
	$item -> {prestation} -> {type} = sql_select_hash ('prestation_types', $item -> {prestation} -> {id_prestation_type});
	
	my ($y, $m, $d) = split /\-/, $item -> {prestation} -> {dt_start};
	$item -> {day} = Day_of_Week ($y, $m, $d);
	$item -> {day_name} = $day_names [$item -> {day} - 1];

	
	$item -> {read_only} = 1;
	
	$item -> {prestation} -> {user}        = sql_select_hash ('users', $item -> {prestation} -> {id_user});
	$item -> {prestation} -> {ids_users} ||= '-1';
	
	$item -> {id_user} = $item -> {prestation} -> {id_user} if $_REQUEST {__edit};

	$item -> {ext_fields} = sql_select_all ("SELECT * FROM ext_fields WHERE fake = 0 AND id IN (" . $item -> {prestation} -> {type} -> {ids_ext_fields} . ") ORDER BY ord");
	
	my @vocs = ('users', {filter => 'id_role < 3 AND id_organisation = ' . $item -> {prestation} -> {type} -> {id_organisation}});
	
	foreach my $field (@{$item -> {ext_fields}}) {
		
		$field -> {id_voc} or next;
		
		push @vocs, 'voc_' . $field -> {id_voc}, {order => 'ord'};
		
	}
	
	$item -> {prestation} -> {id_users} ||= -1;

	add_vocabularies ($item, @vocs,
		users => {filter => "id_organisation = $$_USER{id_organisation} AND id_role > 1"}
#		users => {filter => "id IN ($item->{prestation}->{id_user},$item->{prestation}->{id_users})"}
	);

	my $ids_groups = sql_select_ids ("SELECT id FROM groups WHERE id_organisation = ? AND fake = 0 AND (IFNULL(is_hidden, 0) = 0 OR id = ?)", $_USER -> {id_organisation}, 0 + $_USER -> {id_group});

	$item -> {users} = sql_select_all (<<EOS);
		SELECT
			*
		FROM
			users
		WHERE
			id_organisation = $_USER->{id_organisation}
			AND id_group IN ($ids_groups)
			AND fake = 0
			AND (dt_finish IS NULL OR dt_finish > '$item->{prestation}->{dt_finish}')
			AND id NOT IN ($item->{prestation}->{id_user},$item->{prestation}->{ids_users})
		ORDER BY
			label
EOS
	
	my ($ids, $idx) = ids ($item -> {users});
	
	my $collect = sub {
		
		foreach my $id_user ($i -> {id_user}, split /\,/, $i -> {id_users}) {
		
			$idx -> {$id_user} -> {prestation} = $i;
		
		}
		
	};

	sql_select_loop (<<EOS, $collect, 60 * $item -> {hour_finish} + $item -> {minute_finish}, 60 * $item -> {hour_start} + $item -> {minute_start}, "$item->{prestation}->{dt_finish}$item->{prestation}->{half_finish}", "$item->{prestation}->{dt_start}$item->{prestation}->{half_start}");
		SELECT
			prestations.*
			, prestation_types.label AS prestation_type_label
			, prestation_types.is_half_hour
			, inscriptions.label AS inscription_label
			, inscriptions.nom AS inscription_nom
			, inscriptions.prenom AS inscription_prenom
		FROM
			prestations
			LEFT JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
			LEFT JOIN inscriptions ON (
				inscriptions.id_prestation = prestations.id
				AND 60 * inscriptions.hour_start  + inscriptions.minute_start  < ?
				AND 60 * inscriptions.hour_finish + inscriptions.minute_finish > ?
			)
		WHERE
			prestations.id_user IN ($ids)
			AND prestations.fake = 0
			AND CONCAT(prestations.dt_start,  prestations.half_start)  <= ?
			AND CONCAT(prestations.dt_finish, prestations.half_finish) >= ?
EOS


	foreach my $user (@{$item -> {users}}) {
	
		my $p = $user -> {prestation} or next;
		
		next if $p -> {is_half_hour} == -1 && !$p -> {inscription_label};
		
		$user -> {is_busy} = 1;
	
	}

	__d ($item -> {prestation}, 'dt_start');

	$item -> {week_status_type} = sql_select_hash ('week_status_types', week_status ($item -> {prestation} -> {dt_start}, $_USER -> {id_organisation}));

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



	return $item;

}

1;

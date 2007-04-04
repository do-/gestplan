################################################################################

sub do_create_prestation_types {

	$_REQUEST {id} = sql_do_insert ('prestation_types', {
		id_organisation => $_USER -> {id_organisation},
	});

}

################################################################################

sub do_update_prestation_types {
	
	sql_do_update ('prestation_types', [qw(
		label
		label_short
		length
		is_half_hour
		is_multiday
		ids_ext_fields
		id_day_period
		is_placeable_by_conseiller
		is_private
		length_ext
		id_prestation_type_group
		ids_roles
		ids_rooms
		id_people_number
		is_to_edit
		is_open
		no_stats
		time_step
		ids_users
		half_1_h
		half_1_m
		half_2_h
		half_2_m
		half_1_to_h
		half_1_to_m
		half_2_to_h
		half_2_to_m
	)]);
	
	sql_do ('DELETE FROM prestation_types_ext_fields WHERE id_prestation_type = ?', $_REQUEST {id});

	foreach my $id_ext_field (get_ids ('ext_field')) {
		
		my $ord = $_REQUEST {'_ext_field_' . $id_ext_field} or next;
	
		sql_do_insert ('prestation_types_ext_fields', {
			id_prestation_type => $_REQUEST {id},
			id_ext_field       => $id_ext_field,
			ord                => $ord,
		});
	
	}

}

################################################################################

sub validate_update_prestation_types {
	
	$_REQUEST {_label} or return "#_label#:Vous avez oublié d'indiquer la désignation";
	$_REQUEST {_label_short} or return "#_label_short#:Vous avez oublié d'indiquer l'abréviation";


	$_REQUEST {_id_day_period} = 0;
	foreach (get_ids ('_id_day_period')) {$_REQUEST {_id_day_period} += $_};	
	$_REQUEST {_id_day_period} or return "#_id_day_period#:Vous avez oublié d'indiquer la moitié du jour";
	
	if ($_REQUEST {_is_half_hour} == 1) {
		$_REQUEST {_time_step} > 0 or return "#_time_step#:Vous avez oublié d'indiquer l'horaire";
	}
	elsif ($_REQUEST {_is_half_hour} == -1) {
	
		60 * $_REQUEST {_half_1_h}    + $_REQUEST {_half_1_m}    <  60 * $_REQUEST {_half_1_to_h} + $_REQUEST {_half_1_to_m} or return "#_half_1_to_h#:La fin du matin doît succéder au début";
		60 * $_REQUEST {_half_1_to_h} + $_REQUEST {_half_1_to_m} <= 60 * $_REQUEST {_half_2_h}    + $_REQUEST {_half_2_m}    or return "#_half_1_to_h#:Le début de l'après-midi doît succéder à la fin du matin";
		60 * $_REQUEST {_half_2_h}    + $_REQUEST {_half_2_m}    <  60 * $_REQUEST {_half_2_to_h} + $_REQUEST {_half_2_to_m} or return "#_half_2_to_h#:La fin de l'après-midi doît succéder au début";
	
		$_REQUEST {_length} == 0     or return "#_length#:Le nombre d'inscrits doit être zéro pour des numéros libres";
		$_REQUEST {_length_ext} == 0 or return "#_length_ext#:Le nombre d'inscrits doit être zéro pour des numéros libres";

	}
	
#	$_REQUEST {_length} or return "#_length#:Vous avez oublié d'indiquer le nombre de lignes";
	
	if ($_REQUEST {_is_placeable_by_conseiller} == 2) {
		my @ids = get_ids ('ids_users');
		push @ids, -1;
		unshift @ids, -1;
		$_REQUEST {_ids_users} = join ',', @ids;
	}
	else {
		delete $_REQUEST {_ids_users};
	}

	$_REQUEST {_id_people_number} or return "Vous avez oublié d'indiquer le nombre de collaborateurs";
	
	my @ids = get_ids ('ids_ext_fields');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_ext_fields} = join ',', @ids;

	my @ids = get_ids ('ids_roles');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_roles} = join ',', @ids;

	my @ids = get_ids ('ids_rooms');
	push @ids, -1;
	unshift @ids, -1;
	$_REQUEST {_ids_rooms} = join ',', @ids;

	return undef;
	
}

################################################################################

sub get_item_of_prestation_types {

	my $item = sql_select_hash ('prestation_types');

    $item -> {time_step}   ||= 30 if $item -> {is_half_hour} == 1;
    $item -> {half_1_h}    ||= 9;
    $item -> {half_1_m}    ||= 0;
    $item -> {half_1_to_h} ||= 13;
    $item -> {half_1_to_m}   = 30 unless defined $item -> {half_1_to_m};
    $item -> {half_2_h}    ||= 13;
    $item -> {half_2_to_h} ||= 18;
    $item -> {half_2_m}      = 30 unless defined $item -> {half_2_m};
    $item -> {half_1_m}      = sprintf ('%02d', $item -> {half_1_m});
    $item -> {half_2_m}      = sprintf ('%02d', $item -> {half_2_m});
    $item -> {half_2_to_m}   = sprintf ('%02d', $item -> {half_2_to_m});

	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);

	add_vocabularies ($item,
		ext_fields             => {order => 'ord', filter => 'id_organisation = ' . $_USER -> {id_organisation}},
		day_periods            => {order => 'id', filter => 'id < 3'},
		prestation_type_groups => {filter => 'id > 0'},
		'roles',               => {filter => 'id IN (1,2,3)'},
		'rooms'                => {filter => 'id_organisation = ' . $_USER -> {id_organisation}},
		'users'                => {filter => 'id_role = 2 AND id_organisation = ' . $_USER -> {id_organisation}},
	);

	my $odd = $item -> {id_day_period} % 2;	
	$item -> {id_day_period} = [$odd, $item -> {id_day_period} - $odd];	
	
	if ($item -> {ids_ext_fields}) {
		$item -> {ext_fields_ord} = sql_select_all (<<EOS, $item -> {id});
			SELECT
				ext_fields.id
				, ext_fields.label
				, IFNULL(prestation_types_ext_fields.ord, ext_fields.ord) AS ord
			FROM
				ext_fields
				LEFT JOIN prestation_types_ext_fields ON (prestation_types_ext_fields.id_ext_field = ext_fields.id AND prestation_types_ext_fields.id_prestation_type = ?)
			WHERE
				ext_fields.id IN ($$item{ids_ext_fields})
			ORDER BY
				IFNULL(prestation_types_ext_fields.ord, ext_fields.ord)
EOS
	}

	$item -> {ids_ext_fields} = [grep {$_ > 0} split /,/, $item -> {ids_ext_fields}];
	$item -> {ids_roles}      = [grep {$_ > 0} split /,/, $item -> {ids_roles}];
	$item -> {ids_rooms}      = [grep {$_ > 0} split /,/, $item -> {ids_rooms}];
	$item -> {ids_users}      = [grep {$_ > 0} split /,/, $item -> {ids_users}];

	$item -> {path} = [
		{type => 'prestation_types', name => 'Types de prestations'},
		{type => 'prestation_types', name => $item -> {label}, id => $item -> {id}},
	];

	return $item;
}

################################################################################

sub select_prestation_types {

	my $q = '%' . $_REQUEST {q} . '%';

	my $start = $_REQUEST {start} + 0;

	my ($prestation_types, $cnt) = sql_select_all_cnt (<<EOS, 0 + $_USER -> {id_organisation}, $q, $_USER -> {id_organisation}, {fake => 'prestation_types'});
		SELECT
			prestation_types.*
			, day_periods.label AS day_period_label
			, prestation_type_groups.label AS prestation_type_group_label
			, IFNULL(prestation_type_group_colors.color, prestation_type_groups.color) AS color
		FROM
			prestation_types
			LEFT JOIN day_periods ON prestation_types.id_day_period = day_periods.id
			LEFT JOIN prestation_type_groups ON prestation_types.id_prestation_type_group = prestation_type_groups.id
			LEFT JOIN prestation_type_group_colors ON (
				prestation_type_group_colors.id_prestation_type_group = prestation_type_groups.id
				AND prestation_type_group_colors.id_organisation = ?
			)
		WHERE
			(prestation_types.label LIKE ?)
			AND prestation_types.id_organisation = ?
		ORDER BY
			prestation_types.label_short
		LIMIT
			$start, $$conf{portion}
EOS

	return {
		prestation_types => $prestation_types,
		cnt => $cnt,
		portion => $$conf{portion},
	};
	
}

1;

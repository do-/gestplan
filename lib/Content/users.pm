################################################################################

sub do_change_organisation_users { # navigation vers une autre structure

	sql_do ('UPDATE users SET id_organisation = ? WHERE id = ?', $_REQUEST {_id_organisation}, $_USER -> {id});
	
	delete $_REQUEST {type};

}

################################################################################

sub do_transfer_users {
		
	sql_do ('UPDATE log      SET id_user = ? WHERE id_user = ?', $_REQUEST {id_new}, $_REQUEST {id});
	sql_do ('UPDATE sessions SET id_user = ? WHERE id_user = ?', $_REQUEST {id_new}, $_REQUEST {id});

	sql_do_relink ('users', $_REQUEST {id} => $_REQUEST {id_new});

	sql_do ('DELETE FROM users WHERE id = ?', $_REQUEST {id});
	
	$_REQUEST {id} = $_REQUEST {id_new};

#	delete $_REQUEST {id_new};

	my $href = esc_href ();
	$href =~ s{\&salt\=[\d\.]+}{}gsm;
	
	redirect ($href, {kind => 'js'});
	
}

################################################################################

sub do_deny_users {	
	sql_do ('DELETE FROM map_users_to_rubrics WHERE id_user = ? AND id_rubric = ?', $_REQUEST {id}, $_REQUEST {id_rubric});
	delete $_REQUEST {id_rubric};	
}

################################################################################

sub get_item_of_users {

	my $item = sql_select_hash ("users");
	
	$item -> {id_default_organisation} = delete $item -> {id_organisation};
	
	__d ($item, 'dt_birth', 'dt_start', 'dt_finish');
	
	$_REQUEST {__read_only} ||= !($_REQUEST {__edit} || $item -> {fake} > 0);	

	add_vocabularies ($item,

		organisations => $_USER -> {role} eq 'superadmin' ? {ids => 'users_organisations'} : {},

		roles => {
			order  => 'id',
			filter => $_USER -> {role} eq 'superadmin' ? 'id IN (1,4)' : 'id < 4',
		},

		sites  => {filter => "id_organisation = $_USER->{id_organisation}"},
		groups => {filter => "id_organisation = $_USER->{id_organisation}"},

	);
	
	if ($_USER -> {role} eq 'superadmin' && (!$_REQUEST {__read_only} || @{$item -> {id_organisation}} > 0)) {
	
		$item -> {roles} -> [0] -> {type} = 'hgroup';
		
		$item -> {roles} -> [0] -> {items} = [
		
			{
			
				type      => 'checkboxes',
				label     => '<b>Structures à naviguer</b>',
				values    => $item -> {organisations},
				name      => 'id_organisation',
				height    => 150,
				separator => ' ; ',
				cols      => 3,
			
			},
		
		];
	
	}

	$item -> {path} = [
		{type => 'users', name => 'Utilisateurs'},
		{type => 'users', name => $item -> {label}, id => $item -> {id}},
	];
	
#	$item -> {clones} = sql_select_all (<<EOS, $item -> {id}, $item -> {label});
#		SELECT
#			users.*
#		FROM
#			users
#		WHERE	
#			users.id <> ?
#			AND users.label = ?
#EOS

	$item -> {off_periods} = sql_select_all (<<EOS, $item -> {id}, {fake => 'off_periods'});
		SELECT
			off_periods.*
		FROM
			off_periods
		WHERE	
			id_user = ?
		ORDER BY
			dt_start DESC
EOS

	$item -> {options} = [split /\,/, $item -> {options}];

	return $item;	
	
}

################################################################################

sub validate_update_users {

	$_REQUEST {_prenom} or return "#_prenom#:Vous avez oublié d'indiquer le prénom";
	$_REQUEST {_nom} or return "#_nom#:Vous avez oublié d'indiquer le nom";
	
	$_REQUEST {_label} = $_REQUEST {_prenom} . ' ' . $_REQUEST {_nom};
	
	vld_unique ('users', {field => 'login'}) or return "#_login#:Le login '$_REQUEST{_login}' est déjà occupé, veuillez choisir un autre";
	
	if ($_REQUEST {_dt_start}) {
		vld_date ('dt_start');
	}
	else {
		delete $_REQUEST {_dt_start};
	}

	if ($_REQUEST {_dt_finish}) {
		vld_date ('dt_finish');
	}
	else {
		delete $_REQUEST {_dt_finish};
	}

	$_REQUEST {_id_role} or return "#_id_role#:Vous avez oublié d'indiquer le profil";
				
	if ($_REQUEST {_id_role} == 4) {
	
		delete $_REQUEST {_id_default_organisation}
	
	}
	else {
	
		$_REQUEST {_id_default_organisation} or return "#_id_default_organisation#:Vous avez oublié d'indiquer la structure";
	
	}
	
	$_REQUEST {_options} = '';
	
	foreach (keys %_REQUEST) {	
		/^_options_/ or next;		
		$_REQUEST {_options} .= ",$'";	
	}
	
	if ($_REQUEST {_password}) {
		$_REQUEST {_password} = sql_select_scalar ('SELECT OLD_PASSWORD(?)', $_REQUEST {_password});
	}
	else {
		delete $_REQUEST {_password};
	}

	$_REQUEST {_id_organisation} = delete $_REQUEST {_id_default_organisation};
	
	$_REQUEST {'_id_organisation_' . $_REQUEST {_id_organisation}} = 1;

	return undef;
	
}

################################################################################

sub do_update_users {

	do_update_DEFAULT ();
	
	if ($_USER -> {role} eq 'admin' || $_USER -> {role} eq 'superadmin') {
		sql_do_update ('users', [qw(login id_role mail dt_start dt_finish)]);
	}
	
}

################################################################################

sub do_create_users {

	$_REQUEST {id} = sql_do_insert ('users', {
		label => '',
		id_organisation => $_USER -> {id_organisation},
		id_role => sql_select_scalar ('SELECT id FROM roles WHERE name = ?', 'conseiller'),
	});
	
}

################################################################################

sub select_users {

	my $q = '%' . $_REQUEST {q} . '%';
	
	my $start = $_REQUEST {start} + 0;
	
	my $filter = '';
	
	if ($_USER -> {role} eq 'superadmin') {	
		$filter .= ' AND users.id_role IN (1,4) ';	
	}
	else {
		$filter .= ' AND users.id_organisation = ' . $_USER -> {id_organisation};	
	}
	
	my ($users, $cnt)= sql_select_all_cnt (<<EOS, $_USER -> {id_organisation}, $_USER -> {id_organisation}, $q, $q, {fake => 'users'});
		SELECT
			users.*
			, roles.label  AS role_label
			, sites.label  AS site_label
			, groups.label AS group_label
			, organisations.label AS organisation_label
		FROM
			users
			LEFT JOIN roles  ON users.id_role = roles.id
			LEFT JOIN sites  ON (
				users.id_site = sites.id
				AND sites.id_organisation = ?
			)
			LEFT JOIN groups ON (
				users.id_group = groups.id
				AND groups.id_organisation = ?
			)
			LEFT JOIN organisations on users.id_organisation = organisations.id
		WHERE
			(users.label LIKE ? or users.login LIKE ?)
			$filter
		ORDER BY
			users.label
		LIMIT
			$start, 50 #$$conf{portion}
EOS

	return {
		users => $users,
		cnt => $cnt,
		portion => 50,
	};	

}

1;

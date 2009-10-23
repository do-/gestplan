
################################################################################

sub select_menu_for_superadmin {

	$_USER -> {id_organisation} = -1;

	return [

		{
			name  => 'organisations',
			label => 'Structures',
		},
		{
			name  => 'users',
			label => 'Utilisateurs',
		},
		{
			name  => 'log',
			label => 'Log',
			items => [
				{
					name  => '_info',
					label => 'Versions',
				},
			],
		},
	
		support_menu (),

		{
	    	label  => 'Déconnexion',
	    	href   => "type=_logout",
			side   => 'right_items',
			target => '_top',
		},

	];

}

################################################################################

sub select_menu_for_admin {

	$_REQUEST {__im_delay} = 60 * 1000;

	my $organisations = sql_select_all (q {
		SELECT
			organisations.*
		FROM
			users_organisations
			LEFT JOIN organisations ON (
				users_organisations.id_organisation = organisations.id
				AND organisations.fake = 0
			)
		WHERE
			users_organisations.fake = 0
			AND users_organisations.id_user = ?
			AND users_organisations.id_organisation <> ?
		ORDER BY
			organisations.label
		
	}, $_USER -> {id}, $_USER -> {id_organisation});

	return [

		{
			name  => 'prestations',
			label => 'Planning',
		},
		{
			name  => 'inscriptions',
			label => "Aujourd'hui",
		},
		{
			name  => 'users',
			label => 'Utilisateurs',
			items => [
				{			
					name  => 'user_options',
					label => 'Mes options',
				},
			],	
		},
		{
			
			name  => 'prestation_types',
			label => 'Prestations',
						
			items => [				
				{			
					name  => 'prestation_type_groups',
					label => 'Couleurs',
				},
				{			
					name  => 'ext_fields',
					label => 'Données',
				},
				{			
					name  => 'vocs',
					label => 'Listes',
				},
				
#				BREAK,
#				
#				(map {{href => "/?type=vocs&id=$$_{id}", label => $_ -> {label}}} @{sql_select_all ('SELECT * FROM vocs WHERE fake = 0 AND id_organisation = ? ORDER BY label', $_USER -> {id_organisation})}),
				
				{			
					name  => 'holydays',
					label => 'Jours fériés',
				},				
			
			],
			
		},
		
		{
			
			name    => '_params',
			label   => 'Paramètres',
			no_page => 1,

			items => [

				{
					name  => 'sites',
					label => "Onglets",
				},
				{
					name  => 'groups',
					label => "Regroupements",
				},
				{
					name  => 'rooms',
					label => "Ressources",
				},
				{
					href  => "/?type=organisations_local&id=$_USER->{id_organisation}",
					label => "Structure",
				},
			],
		},
			
		stat_menu (),
		
		support_menu (),

		extra_menu (),
	
		{
			label   => 'Structures',
			no_page => 1,
			off     => 0 == @$organisations,
			
			items   => [
			
				map {{
				
					label  => $_ -> {label},
					href   => "/?type=users&action=change_organisation&_id_organisation=$_->{id}",
					target => '_top',
				
				}} @$organisations
			
			],
			
		},
		
	
	];

}

################################################################################

sub select_menu_for_conseiller {

	$_REQUEST {__im_delay} = 60 * 1000;

	return [

		{
			name  => 'inscriptions',
			label => "Aujourd'hui",
		},
		{
			name  => 'prestations',
			label => 'Planning',
		},
		{			
			name  => 'user_options',
			label => 'Mes options',
		},
		
		stat_menu (),
	
		support_menu (),

		extra_menu (),

	];

}

################################################################################

sub select_menu_for_accueil {

	$_REQUEST {__im_delay} = 60 * 1000;

	return [

		{
			name  => 'prestations',
			label => 'Planning',
		},
		{			
			name  => 'user_options',
			label => 'Mes options',
		},
		
		stat_menu (),
		
		support_menu (),
	
		extra_menu (),

	];

}


################################################################################

sub select_menu {
	return [];
}

1;

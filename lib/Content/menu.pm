
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

	];

}

################################################################################

sub select_menu_for_admin {

	$_REQUEST {__im_delay} = 60 * 1000;

	return [

		{
			name  => 'prestations',
			label => 'Planning activités',
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
					label => "Sites",
				},
				{
					name  => 'groups',
					label => "Regroupements",
				},
				{
					name  => 'rooms',
					label => "Ressources",
				},
			],
		},
			
		stat_menu (),
		
		support_menu (),

		extra_menu (),
	
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
			label => 'Planning activités',
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
			label => 'Planning activités',
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

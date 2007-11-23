
################################################################################

sub select_menu_for_superadmin {

	$_USER -> {id_organisation} = -1;

	return [

		{
			name  => 'organisations',
			label => 'Missions locales',
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
	
	];

}

################################################################################

sub select_menu_for_admin {

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
					label => 'Données propres',
				},
				{			
					name  => 'vocs',
					label => 'Listes choix',
				},
				
				BREAK,
				
				(map {{href => "/?type=vocs&id=$$_{id}", label => $_ -> {label}}} @{sql_select_all ('SELECT * FROM vocs WHERE fake = 0 AND id_organisation = ? ORDER BY label', $_USER -> {id_organisation})}),
				
				{			
					name  => 'holydays',
					label => 'Jours fériés',
				},				
			
			],
			
		},
		{
			name  => 'rooms',
			label => "Salles",
		},
		{
			name  => 'sites',
			label => "Sites",
		},

		{
			name  => 'groups',
			label => "Regroupements",
		},
		
		stat_menu (),
		
		extra_menu (),
	
	];

}

################################################################################

sub select_menu_for_conseiller {

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
	
		extra_menu (),

	];

}

################################################################################

sub select_menu_for_accueil {

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
	
		extra_menu (),

	];

}


################################################################################

sub select_menu {
	return [];
}

1;

################################################################################

sub draw_item_of_users {

	my ($data) = @_;
	
	draw_form ({

		right_buttons => [ del ($data) ],
				
		name  => 'f1',
		
		menu  => user_menu (),
		
	}, $data,
		[
			{
				name  => 'prenom',
				label => 'Prénom',
				size  => 41,
				max_len => 255,
				off   => $_REQUEST {__read_only},
			},
			{
				name  => 'nom',
				label => 'Nom',
				size  => 41,
				max_len => 255,
				off   => $_REQUEST {__read_only},
			},
			{
				name  => 'label',
				label => 'Nom et prénom',
				type  => 'static',
				off   => !$_REQUEST {__read_only},
			},
			{
				name  => 'login',
				mandatory  => 1,
				label => 'login',
				size  => 41,
				max_len => 255,
				off   => $_USER -> {role} ne 'admin' && $_USER -> {role} ne 'superadmin',
			},
			{
				name  => 'password',
				label => 'Mot de passe',
				type  => 'password',
				size  => 54,
				off   => $_USER -> {role} ne 'admin' && $_USER -> {role} ne 'superadmin',
			},
			{
				name  => 'mail',
				label => 'E-mail',
				size  => 41,
				max_len => 255,
				off   => $_USER -> {role} ne 'admin' && $_USER -> {role} ne 'superadmin',
			},
#				{
#					name  => 'ip',
#					label => 'adresse IP',
#					size  => 15,
#					off   => $_USER -> {role} ne 'admin',
#				},
#				{
#					name  => 'mac',
#					label => 'adresse MAC',
#					size  => 17,
#					off   => $_USER -> {role} ne 'admin',
#				},
#				{
#					name   => 'demo_level',
#					label  => 'Ðåæèì äîñòóïà',
#					type   => 'radio',
#					values => [
#						{id => 0, label => 'Íîðìàëüíûé'},
#						{id => 1, label => 'Òîëüêî ÷òåíèå'},
#						{id => 2, label => 'Áåç ÷èñëîâûõ äàííûõ'},
#					],
#					off => $_USER -> {role} ne 'admin',
#				},

			{
				name       => 'id_default_organisation',
				label      => 'Structure',
				type       => 'select',
				values     => $data -> {organisations},
				empty      => '',
				read_only  => $_USER -> {role} ne 'superadmin',
				add_hidden => 1,
			},
			{
				name   => 'id_role',
				label  => 'Profil',
				type   => 'radio',
				values => $data -> {roles},
				off   => $_USER -> {role} ne 'admin' && $_USER -> {role} ne 'superadmin',
			},
			{
				name   => 'id_group',
				label  => 'Regroupement',
				type   => 'select',
				empty  => ' ',
				values => $data -> {groups},
				off    => 0 == @{$data -> {groups}},
			},
			{
				name   => 'is_person',
				label  => 'Personne',
				type   => 'checkbox',
			},
			{
				name   => 'id_site',
				label  => 'Onglet',
				type   => 'select',
				empty  => ' ',
				values => $data -> {sites},
				off    => 0 == @{$data -> {sites}},
			},
			{
				name   => 'options',
				label  => 'Options',
				type   => 'checkboxes',
				values => [
					{
						id    => 'support',
						label => 'Support' ,
						items => [
							{
								id    => 'support_developer',
								label => 'Développeur',
							},
						],
					},
				],
			},
			
			{
				
				type  => 'hgroup',
				
				label => 'En activité du',
				
				items => [
					{
						type => 'date',
						no_read_only => 1,
						name => 'dt_start',
					},
					{
						type => 'date',
						label => 'au',
						no_read_only => 1,
						name => 'dt_finish',
					},
				],
				
			},
			
		]

	)
	
	.
	
	draw_table (
	
	   	[
	   		'Du',
	   		'Au',
		],
		
		sub {
		
		    __d ($i, 'dt_start', 'dt_finish');
		    
		    draw_cells ({
		    	href => "/?type=off_periods&id=$$i{id}",
			}, [
				$i -> {dt_start},
				$i -> {dt_finish},
			])		
		
		},
		
		$data -> {off_periods},
		
		{
		
			title => {label => "Périodes d'absence"},
			
			off => !$_REQUEST {__read_only},
			
			top_toolbar => [{},
				{
					icon  => 'create',
					label => 'Ajouter',
					href  => "/?type=off_periods&action=create&id_user=$$data{id}",
					keep_esc => 0,
				}
			],
		
		}, 	
		
	
	)	
	
	;
	
}

################################################################################

sub draw_users {
	
	my ($data) = @_;
	
	return
			
		draw_table (
		
			[
				'Nom',
				{
					label  => 'Mission locale',
					hidden => $_USER -> {role} ne 'superadmin',
				},
				'Profil',
				{
					label  => 'Regroupement',
					hidden => $_USER -> {role} eq 'superadmin',
				},
				'Login',
				{
					label  => 'Site',
					hidden => $_USER -> {role} eq 'superadmin',
				},
			],

			sub {

				draw_cells ({
					href => "/?type=users&id=$$i{id}",
				}, [
					$i -> {label},
					{
						label  => $i -> {organisation_label},
						hidden => $_USER -> {role} ne 'superadmin',
					},
					$i -> {role_label},
					{
						label  => $i -> {group_label},
						hidden => $_USER -> {role} eq 'superadmin',
					},
					$i -> {login},
					{
						label  => $i -> {site_label},
						hidden => $_USER -> {role} eq 'superadmin',
					},
				])
								
			},
			
			$data -> {users},
			
			{
				
				title => {label => 'Utilisateurs'},
			
				top_toolbar => [
				
					{
						keep_params => ['type'],
					},
					
					{
						icon => 'create',
						label => 'Créer',
						href => "?type=users&action=create",
					},
		
					{
						type  => 'input_text',
						label => 'Chercher',
						name  => 'q',
						keep_params => [],
					},
					
					{
						type => 'pager',
						cnt    => 0 + @{$data -> {users}},
						total  => $data -> {cnt},
						portion => $data -> {portion},
					},
					
					fake_select (),
					
				],
				
			}
			
		)
		
}

1;

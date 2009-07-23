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
				label => 'Pr�nom',
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
				label => 'Nom et pr�nom',
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
#					label  => '����� �������',
#					type   => 'radio',
#					values => [
#						{id => 0, label => '����������'},
#						{id => 1, label => '������ ������'},
#						{id => 2, label => '��� �������� ������'},
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
								label => 'D�veloppeur',
							},
						],
					},
				],
			},
						
			{
				name   => 'id_site',
				label  => 'Appartient aux onglets',
				type   => 'checkboxes',
				values => Storable::dclone $data -> {sites},
				off    => 0 == @{$data -> {sites}},
			},

			{
				name   => 'id_default_site',
				label  => 'Onglet principal',
				type   => 'select',
				empty  => ' ',
				values => $data -> {sites},
				off    => 0 == @{$data -> {sites}},
			},

			{
				
				type  => 'hgroup',
				
				label => 'En activit� du',
				
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
		
			title => {label => "P�riodes d'absence"},
			
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
	
		draw_hr (height => 10)
		
		.
	
		draw_window_title ({
			label => 'Utilisateurs'
		})
	
		.
		
		draw_toolbar (
		
			{
				keep_params => ['type'],
			},
			
			draw_toolbar_button ({
				icon => 'create',
				label => 'Cr�er',
				href => "?type=users&action=create",
			}),

			draw_toolbar_input_text ({
				label   => 'Chercher',
				name   => 'q',
				keep_params => [],
			}),
			
			draw_toolbar_pager ({
				cnt    => 0 + @{$data -> {users}},
				total  => $data -> {cnt},
				portion => $data -> {portion},
			}),
			
			fake_select (),
			
		)
		
		.

		draw_table (
		
			[
				'Nom',
				{
					label  => 'Mission locale',
					hidden => $_USER -> {role} ne 'superadmin',
				},
				'Profil',
				'Regroupement',
				'Login',
				'Onglet principal',
			],

			sub {

				draw_text_cells ({
					href => "/?type=users&id=$$i{id}",
				}, [
					$i -> {label},
					{
						label  => $i -> {organisation_label},
						hidden => $_USER -> {role} ne 'superadmin',
					},
					$i -> {role_label},
					$i -> {group_label},
					$i -> {login},
					$i -> {site_label},
				])
								
			},
			
			$data -> {users}
			
		)
		
}

1;

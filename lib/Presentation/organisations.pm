################################################################################

sub draw_item_of_organisations {
	
	my ($data) = @_;

	draw_form ({
			name => 'f1',
			right_buttons => [ del ($data) ],
		},
		$data,
		[
			{
				name  => 'label',
				label => 'Désignation',
			},
			{
				name   => 'ids_partners',
				label  => 'Partenaires',
				type   => 'checkboxes',
				values => $data -> {organisations},
			},
			{
				name  => 'href',
				label => 'Menu extra',
			},
		],
	)
			
		.

		draw_table (
		
			[
				'Nom',
				'Profil',
				'Regroupement',
				'Login',
				'Site',
			],

			sub {

				draw_text_cells ({
					href => "/?type=users&id=$$i{id}",
				}, [
					$i -> {label},
					$i -> {role_label},
					$i -> {group_label},
					$i -> {login},
					$i -> {site_label},
				])
								
			},
			
			$data -> {users},
			
			{

				title => {label => 'Utilisateurs'},
				
				off => !$_REQUEST {__read_only},

				top_toolbar => [
				
					{
						keep_params => ['type', 'id'],
					},
					
		#			draw_toolbar_button ({
		#				icon => 'create',
		#				label => 'Créer',
		#				href => "?type=users&action=create",
		#			}),
		
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
					
				],

			},
			
		)

}

################################################################################

sub draw_organisations {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=organisations&id=$$i{id}",
				}, [
					$i -> {label},
				])

			},

			$data -> {organisations},

			{
				
				title => {label => 'Structures'},

				top_toolbar => [{
							keep_params => ['type', 'select'],
						},
					{
						icon    => 'create',
						label   => 'Créer',
						href    => '?type=organisations&action=create',
					},

					{
						type        => 'input_text',
						icon        => 'tv',
						label       => 'Chercher',
						name        => 'q',
						keep_params => [],
					},

					{
						type    => 'pager',
						cnt     => 0 + @{$data -> {organisations}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},

					fake_select (),

				],

			},
			
		);

}

1;

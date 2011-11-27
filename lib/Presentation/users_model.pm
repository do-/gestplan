################################################################################

sub draw_item_of_users_model {
	
	my ($data) = @_;
	
	js q {var isBlocked = false};
	
	draw_form ({

		no_edit => 1,
				
		name  => 'f1',
		
		menu  => user_menu (),
		
	}, $data,
		[
			{
				name  => 'prenom',
				label => 'Pr�nom',
				size  => 40,
				off   => $_REQUEST {__read_only},
			},
			{
				name  => 'nom',
				label => 'Nom',
				size  => 40,
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
				off   => $_USER -> {role} ne 'admin' && $_USER -> {role} ne 'superadmin',
			},
			{
				name  => 'password',
				label => 'Mot de passe',
				type  => 'password',
				off   => $_USER -> {role} ne 'admin' && $_USER -> {role} ne 'superadmin',
			},
			{
				name       => 'id_organisation',
				label      => 'Mission locale',
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
	   		'Jour',
	   		' ',
	   		map {{
			   	label => $_ -> {label},
			   	href  => "/?type=models&id=$_->{id}",
			}} @{$data -> {models}},
		],
		
		sub {
		
		    __d ($i, 'dt_start', 'dt_finish');
		
		    draw_cells ({
#		    	href => "/?type=off_periods&id=$$i{id}",
			}, [
				{
					label   => $i -> {label},
					rowspan => $i -> {rowspan},
					hidden  => $i -> {hidden},
					attributes => {width => 10},
					bold    => 1,
					bgcolor => '#efefef',
				},
				{
					label => $i -> {period_label},
					attributes => {width => 10},
					bold    => 1,
					bgcolor => '#efefef',
				},
				map {
				
					my $d = $i -> {by_model} -> {$_ -> {id}};
				
					{
						label => $d -> {prestation_model_label},
						bgcolor => $d -> {color},
						attributes => {onDblClick => "if (!isBlocked) {isBlocked = true; nope (\"$d->{href}\", \"invisible\")}"},
					},

				} @{$data -> {models}}

			])		
		
		},
		
		$data -> {days},
		
		{
		
			title => {label => "Prestations"},
			
			off => !$_REQUEST {__read_only},
			
			top_toolbar => [{
				keep_params => ['type', 'id'],
			},
				{
					type   => 'input_select',
					label  => 'Prestation',
					show_label => 1,
					name   => 'id_prestation_type',
					values => $data -> {prestation_types},
					empty  => '',
				},
			],
		
		}, 	
		
	
	)	
	
	;
	

}

1;

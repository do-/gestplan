

################################################################################

sub draw_item_of_organisations_local {

	my $data = $_[0];	

	$_REQUEST {__focused_input} = '_label';

	draw_form ({
				
			no_edit => $data -> {no_del},
			
			path => [
				{type => 'organisations_local', name => action_type_label},
				{type => 'organisations_local', name => $data -> {label}, id => $data -> {id}},
			],
			
		},
		
		$data,
		
		[
		
			{
				name    => 'label',
				label   => 'Désignation',
				type    => 'static',
			},

			{
				name   => 'days',
				label  => 'Jours travaillés',
				type   => 'checkboxes',
				values => [map {{id => ($_ + 1), label => $day_names [$_]}} (0 .. @day_names - 1)],
			},			
			
			{
				type   => 'banner',
				label  => 'Onglets spéciaux',
			},

			{
				name    => 'empty_site_label',
				label   => "Prestations locales",
				size    => 80,
			},

			{
				name    => 'partners_site_label',
				label   => "Partenaires",
				size    => 80,
			},

		],

	);

}

1;

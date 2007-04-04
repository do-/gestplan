################################################################################

sub draw_organisations_acl {
	
	my ($data) = @_;

	draw_form ({
			right_buttons => [ del ($data) ],
		},
		$data,
		[
			{
				name  => 'ids_roles_prestations',
				label => 'Profils pour les statistiques des prestations',
				type  => 'checkboxes',
				values => $data -> {roles},
			},
			{
				name  => 'ids_roles_inscriptions',
				label => 'Profils pour les statistiques des inscriptions',
				type  => 'checkboxes',
				values => $data -> {roles},
			},
		],
	);


}

1;

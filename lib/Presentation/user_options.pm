################################################################################

sub draw_user_options {

	my ($data) = @_;
	
	draw_form ({

		right_buttons => [ ],
				
		name  => 'f1',
		
	}, $data,
		[
			{
				name  => 'label',
				label => 'Nom et pr�nom',
				type  => 'static',
			},
			{
				name  => 'login',
				label => 'login',
				size  => 40,
			},
			{
				name  => 'password',
				label => 'mot de passe',
				type  => 'password',
				size  => 40,
			},
			{
				label  => 'P�riode de rafra�chissement',
				name => 'refresh_period',
				size  => 4,
			},
			{
			
				name  => 'no_popup',
				label => 'Pop-ups',
				type  => 'select',
				values => [
					{id => 0, label => 'Monter au-dessus de toutes les fen�tres'},
					{id => 1, label => 'Montrer en cadre de la fen�tre GestPlan'},
				],
				
			},
			
		]

	)
	
	;

}

1;

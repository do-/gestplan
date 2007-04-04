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
				label => 'Nom et prénom',
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
				label  => 'Période de rafraîchissement',
				name => 'refresh_period',
				size  => 4,
			},
			
		]

	)
	
	;

}

1;

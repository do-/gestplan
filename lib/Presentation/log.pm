################################################################################

sub draw_item_of_log {

	my ($data) = @_;
	
	draw_form ({}, $data,
		[
			{
				name  => 'dt',
				label => 'Date',
			},
			{
				name  => 'id_user',
				label => 'Utilisateur',
				values => $data -> {users},
			},
			{
				name  => 'type',
				label => 'Type',
			},
			{
				name  => 'id_object',
				label => "ID de l'objet",
				href  => "/?type=$$data{type}&id=$$data{id_object}&__popup=1",
				target => '_blank',
			},
			{
				name  => 'action',
				label => 'Action',
			},
			{
				name  => 'error',
				label => 'Erreur',
				off   => !$data -> {error},
			},
		]
	)
	
	.
	
	draw_table (
	
		['Nom', 'Valeur'],
		
		sub {
		
			draw_text_cells ({}, [
				$i -> {label},
				{
					label => $i -> {value},
					max_len => 120,
				},
			])
		
		},
		
		$data -> {params_list},
		
		{
			title => {label => 'Paramètres'},
			off   => 0 == @{$data -> {params_list}},
		}
	
	)
	
	
}

################################################################################

sub draw_log {
	
	my ($data) = @_;
	
	return
	
		draw_table (
			
			['Date', 'Utilisateur', 'IP', 'MAC', 'Action', 'Type', 'ID', 'Erreur'],
		
			sub {
			
				delete $i -> {id_user} if $_REQUEST {_id_user};
			
				$i -> {ip} .= " ($$i{ip_fw})" if $i -> {ip_fw};
			
				draw_text_cells ([
					{
						label => $i -> {dt},
						href  => "/?type=log&id=$$i{id}&__popup=1",
						target => '_blank',
					},
					{
						label => $i -> {label},
						href  => {id_user => $i -> {id_user}},
					},
					$i -> {ip},
					$i -> {mac},
					$i -> {action},
					{
						label => $i -> {type},
						href  => {object_type => $i -> {type}},
					},
					{
						label  => $i -> {id_object},
						href   => "/?type=$$i{type}&id=$$i{id_object}&__popup=1",
						target => '_blank',
					},
					$i -> {error},
				])
			},
			
			$data -> {log},
			
			{			
	
				title => {label => 'Log'},
			
				top_toolbar => [
		
					{
						keep_params => ['type'],
					},
				
					{ type => 'pager' },

					{
						type   => 'input_text',
						label  => 'Type',
						keep_params => [],
						name   => 'object_type',
					},
		
					{
						type   => 'input_text',
						label  => 'Action',
						keep_params => [],
						name   => 'object_action',
					},
		
					{				
						type   => 'input_select',
						name   => 'id_user',
						values => $data -> {users},
						empty  => 'Tout utilisateur'
					},
					
				],
				
			},
				
		)			
			
		
}


1;

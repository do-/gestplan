

################################################################################

sub select_task_notes {
	
	my $data = {};

	if ($_USER -> {options_hash} -> {support_developer}) {
	
		add_vocabularies ($data,
			users => {in => sql ('task_notes(id_user)' => [[fake => 0]])},
		),
	
	}
	else {
	
		$_REQUEST {id_user} = $_USER -> {id};		
	
	}

	sql ($data,
			
		task_notes => [
	
			'id_user',
			
			['label LIKE %?%' => $_REQUEST {q}],

			[ ORDER => 'id DESC'],

			[ LIMIT => [0 + $_REQUEST {start}, $conf -> {portion}]],

		],
			
		'users', 'tasks', 'task_status(*)'
		
	);	
	
	return $data;

}

1;

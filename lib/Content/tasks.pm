
################################################################################

sub do_print_tasks { # export MS Word

	$_REQUEST {__response_sent} = 1;
	
	$r -> status (200);
	$r -> header_out ('Content-Disposition' => "attachment;filename=TACHE_$_REQUEST{id}.doc");
	$r -> send_http_header ('application/octet-stream');
	$r -> print (qq{<html><body>});
	
	sql (task_notes => [
		[id_task => $_REQUEST{id}],
		[ORDER   => 'id'],
	],
		
		'users',
	
	sub {
	
		__d ($i, 'dt');
		
		my $body = $i -> {label};
		
		if ($i -> {body}) {
		
			$body .= "\n$i->{body}";
		
			$body =~ s{[\n\r]+}{<p>}gsm;

		}

		$r -> print (qq {<p><i>$i->{dt}, <b>$i->{user}->{label}</b></i>:<blockquote>$body</blockquote>});
	
	});

}

################################################################################

sub do_create_tasks {

	$_REQUEST {id} = sql_do_insert (tasks => {
		id_user  => $_USER -> {id},
		id_task_status => 100,
	});

}


################################################################################

sub validate_update_tasks {

	my $data = sql ('tasks');
	
	if ($data -> {fake} > 0) {

		$_REQUEST {_label} or return "#_label#:Vous avez oubli� d'entituler la t�che";

		$_REQUEST {_id_task_severity} or return "#_id_task_severity#:Vous avez oubli� de marquer la s�v�rit�";
		$_REQUEST {_id_task_priority} or return "#_id_task_priority#:Vous avez oubli� de marquer la priorit�";
		$_REQUEST {_id_task_reproductibility} or return "#_id_task_reproductibility#:Vous avez oubli� de marquer la reproductibilit�";		

	}
	else {

		$_REQUEST {_id_task_status} or return "Vous avez oubli� de choisir votre action";
		$_REQUEST {_note_label}     or return "#_note_label#:Vous avez oubli� d'entituler le message";

	}

	undef;	

}

################################################################################

sub do_update_tasks {

	my $data = sql ('tasks');

	if ($data -> {fake} > 0) {

		my $id = $_REQUEST {id};
	
		$_REQUEST {id} = sql_do_insert (task_notes => {
			fake    => 0,
			id_user => $_USER -> {id},
			id_task => $id,
			id_task_status => 100,
			id_log  => $_REQUEST {_id_log},	
			label   => $_REQUEST {_label},
			body    => $_REQUEST {_body},
		});	
	
		sql_upload_file ({
			name => 'file',
			dir => 'upload/images',
			table => 'task_notes',
			file_name_column => 'file_name',
			size_column => 'file_size',
			type_column => 'file_type',
			path_column => 'file_path',
		});
		
		sql_do ('UPDATE tasks SET fake = 0, label = ?, id_task_note = ? WHERE id = ?', $_REQUEST {_label}, $_REQUEST {id}, $id);
				
		$_REQUEST {_id_task_note} = $_REQUEST {id};
		
		$_REQUEST {id} = $id;
		
		sql_do_update (tasks => [qw(
			id_task_note
			label
			id_task_reproductibility
			id_task_severity
			id_task_priority
		)]);
		
	}
	else {
	
		my $id = $_REQUEST {id};
	
		$_REQUEST {id} = sql_do_insert (task_notes => {
			fake             => 0,
			id_user          => $_USER -> {id},
			id_task          => $id,
			id_task_status   => $_REQUEST {_id_task_status},
			id_log           => $_REQUEST {_id_log},	
			label            => $_REQUEST {_note_label},
			body             => $_REQUEST {_body},
		});	
	
		sql_upload_file ({
			name             => 'file',
			dir              => 'upload/images',
			table            => 'task_notes',
			file_name_column => 'file_name',
			size_column      => 'file_size',
			type_column      => 'file_type',
			path_column      => 'file_path',
		});
		
		sql_do ('UPDATE tasks SET id_task_note = ?, id_task_status = ? WHERE id = ?', $_REQUEST {id}, $_REQUEST {_id_task_status}, $id);
		
		$_REQUEST {id} = $id;
	
	}
	
	@mail_recipients = $_REQUEST {_id_task_status} =~ /^2/ ? $data -> {id_user} : sql_select_col ('SELECT id FROM users WHERE fake = 0 AND options LIKE ?', '%support_developer%');
		
	my $status = sql_select_scalar ('SELECT label FROM task_status WHERE id = ?', $_REQUEST {_id_task_status} || 100);
	
	$status =~ s{^A }{� };
	$status =~ s{�$}{�e};
	$status =~ y{AC}{ac};
	
	$data -> {label} ||= $_REQUEST {_label};

	send_mail ({
		to	           => \@mail_recipients,
		subject	       => "GestPlan: la t�che $data->{id} est $status ($data->{label})",
		text	       => "$_REQUEST{_note_label}\n\n$_REQUEST{_body}",
		href	       => "/?type=tasks&id=$data->{id}",
		body_charset   => 'windows-1252',
		header_charset => 'windows-1252',
	});

}

################################################################################

sub get_item_of_tasks {

	my $data = sql ('tasks');
	
#	$data -> {no_del} ||= 1 if $data -> {id_user} != $_USER -> {id};

#	$_REQUEST {__read_only} ||= !($data -> {fake} > 0);

	add_vocabularies ($data,
		task_priorities => {order => 'id'},
		task_severities => {order => 'id'},
		task_reproductibilities => {order => 'id'},
	);

#	$data -> {clones} = sql (tasks => [
#		['label LIKE', substr ($data -> {label}, 0, ($_REQUEST {first} ||= 10)) . '%'],
#	]);

	sql ($data, task_notes => [
		[ id_task => $data -> {id} ],
		[ ORDER   => ['id'] ],
	], 'users', 'task_status(*)');
	
	if ($data -> {id_user} == $_USER -> {id}) {

		if ($data -> {id_task_status} == 200) {
		
			$data -> {actions} = [
				{id => 300, label => 'Accepter'},
				{id => 100, label => 'Retourner'},
			];
		
		}
		elsif ($data -> {id_task_status} == 201) {
		
			$data -> {actions} = [
				{id => 100, label => 'Pr�ciser'},
				{id => 301, label => 'Annuler'},
			];
		
		}
		elsif ($data -> {id_task_status} == 100 && !$data -> {fake}) {
		
			$data -> {actions} = [
				{id => 100, label => 'Compl�ter'},
			];
		
		}

	}
	
	if ($_USER -> {options_hash} -> {support_developer}) {
	
		if ($data -> {id_task_status} == 100) {
		
			$data -> {actions} = [
				{id => 200, label => 'Reporter le succ�s'},
				{id => 201, label => 'Demander la pr�cision'},
			];
		
		}
	
	}

	return $data;

}

################################################################################

sub select_tasks {

	my $data = {};

	add_vocabularies ($data,
		task_priorities => {order => 'id'},
		task_severities => {order => 'id'},
		task_reproductibilities => {order => 'id'},
	);

	if ($_USER -> {options_hash} -> {support_developer}) {
	
		add_vocabularies ($data,
			users => {in => sql ('tasks(id_user)' => [[fake => 0]])},
		),

		$data -> {task_status} = [
			{id =>   100, label => 'A faire'},
			{id => - 200, label => 'A verifier'},
			{id => - 300, label => 'Archive'},
			{id =>   201, label => 'A preciser'},
			{id =>   200, label => 'A confirmer'},
			{id =>   300, label => 'Confirm�'},
			{id =>   301, label => 'Annul�'},
		];
		
		exists $_REQUEST {id_task_status} or $_REQUEST {id_task_status} = 100;
	
	}
	else {
	
		$_REQUEST {id_user} = $_USER -> {id};		
		
		$data -> {task_status} = [
			{id => - 100, label => 'A surveiller'},
			{id =>   100, label => 'A faire'},
			{id => - 200, label => 'A v�rifier'},
			{id => - 300, label => 'Archive'},
			{id =>   201, label => 'A pr�ciser'},
			{id =>   200, label => 'A confirmer'},
			{id =>   300, label => 'Confirm�'},
			{id =>   301, label => 'Annul�'},
		];

		exists $_REQUEST {id_task_status} or $_REQUEST {id_task_status} = - 100;
	
	}
	
	my $id_task_status =
		$_REQUEST {id_task_status} == - 100 ? '100,200,201' :
		$_REQUEST {id_task_status} == - 200 ? '200,201' :
		$_REQUEST {id_task_status} == - 300 ? '300,301' :
		$_REQUEST {id_task_status}
	;
	
	sql ($data,
			
		tasks => [
	
			'id_user',
			'id_task_severity',
			'id_task_priority',
			'id_task_reproductibility',
			
			['label LIKE %?%' => $_REQUEST {q}],
			
			['id_task_status IN' => $id_task_status],
			
			[ LIMIT => [0 + $_REQUEST {start}, $conf -> {portion}]],
			
			[ ORDER => 'id'],
		
		],
			
		'users', 'task_status(*)', 'task_notes', 'task_priorities', 'task_severities', 'task_reproductibilities',

	);

}

1;

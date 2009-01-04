

################################################################################

sub draw_item_of_tasks {

	my ($data) = @_;

	$_REQUEST {__focused_input} = '_label';

	draw_form ({
				
			no_ok => $data -> {fake} <= 0,
			
			path => [
				{type => 'tasks', name => 'Support'},
				{type => 'tasks', name => $data -> {label}, id => $data -> {id}},
			],
			
		},
		
		$data,
		
		[

			{
				name    => 'id',
				label   => 'ID',
				type    => 'static',
			},

			{
				name    => 'label',
				label   => 'Sujet',
				size    => 80,
				max_len => 255,
				read_only => $data -> {fake} <= 0,
			},

			{
				name    => 'body',
				label   => 'Description',
				type    => 'text',
				rows    => 10,
				cols    => 120,
				off     => $data -> {fake} <= 0,
			},

			{
				name    => 'file',
				label   => 'Fichier',
				type    => 'file',
				size    => 80,
				off     => $data -> {fake} <= 0,
			},

#			{
#				name   => 'id_user',
#				label  => 'Пользователь',
#				type   => 'select',
#				values => $data -> {users},
#				empty  => '[Выберите пользователя]',
#				other  => '/?type=users',
#			},

#			{
#				name   => 'id_org',
#				label  => 'Организация',
#				type   => 'suggest',
#				size    => 40,
#				values => sub {sql (orgs => ['id',
#					['label LIKE ?%' => $_REQUEST {_id_org}],
#				])},
#			},

		],

	)

	.

	draw_table (
	
		[

			sub {
			
				__d ($i, 'dt');
			
				draw_cells ({
	
				},[
					
					{
						label      => $i -> {dt},
						attributes => {width => 1},
						status     => $i -> {task_status},
					},
					$i -> {label},
					$i -> {user} -> {label},
					{
						label  => $i -> {file_name},
						href   => "/?type=task_notes&id=$i->{id}&action=download",
						target => 'invisible',
					},
					
				]),
			
			},
	
			sub {
			
				$i -> {body} or return undef;
			
				draw_cells ({
	
				},[
					
					' ',
					{
						label   => $i -> {body},
						no_nobr => 1,
						max_len => 1000000,
						colspan => 3,
						level   => 1,
					},
					
				]),
			
			},
			
		],
		
		$data -> {task_notes},
		
		{
			
			title => {label => 'Historique', height => 1},
			
#			off   => !$_REQUEST{__read_only} || @{$data -> {clones}} < 2,
			off   => $data -> {fake} > 0,
			
			name  => 't1',
#						
#			top_toolbar => [{
#				keep_params => ['type', 'id'],
#			},
#				{
#					name  => 'first',
#					type  => 'input_text',
#					label => 'По скольким буквам',
#					size  => 2,
#					keep_params => [],
#				},
#			],
#			
#			toolbar => draw_centered_toolbar ({},
#				
#				[
#					{
#						icon  => 'delete',
#						label => 'слить выделенные записи с текущей',
#						href  => "javaScript:if(confirm('Вы уверены, что все выделенные записи совпадают по смыслу с текущей?')) document.forms ['t1'].submit()",
#					}
#				]
#
#			),

		}

	)

	.

	draw_form ({
							
			path => ' ',

			name => 'ff',
			
			off => !$data -> {actions},
			
		},
		
		$data,
		
		[

			{
				name    => 'id_task_status',
				label   => 'Action',
				values  => $data -> {actions},
				type    => 'radio',
			},

			{
				name    => 'note_label',
				label   => 'Titre',
				size    => 80,
				max_len => 255,
			},

			{
				name    => 'body',
				label   => 'Message complиt',
				type    => 'text',
				rows    => 5,
				cols    => 80,
			},

			{
				name    => 'file',
				label   => 'Fichier',
				type    => 'file',
				size    => 80,
			},

#			{
#				name   => 'id_user',
#				label  => 'Пользователь',
#				type   => 'select',
#				values => $data -> {users},
#				empty  => '[Выберите пользователя]',
#				other  => '/?type=users',
#			},

#			{
#				name   => 'id_org',
#				label  => 'Организация',
#				type   => 'suggest',
#				size    => 40,
#				values => sub {sql (orgs => ['id',
#					['label LIKE ?%' => $_REQUEST {_id_org}],
#				])},
#			},

		],

	)
	
	
	;

}



################################################################################

sub draw_tasks {

	my ($data) = @_;

	return

		draw_table (

			[
				'No',
				'Tвche',
				'Auteur',
			],

			sub {

				draw_cells ({
					href => "/?type=tasks&id=$$i{id}",
				},[
					
					{
						label  => $i -> {id},
						status => $i -> {task_status},
					},
	
					$i -> {label},
					$i -> {user} -> {label},

				])

			},

			$data -> {tasks},

			{
				
				name => 't1',
				
				title => {label => 'Tвches pour dйveloppeurs'},

				top_toolbar => [{
						keep_params => ['type', 'select'],
					},

					{
						icon  => 'create',
						label => 'Ajouter',
						href  => '?type=tasks&action=create',
					},

					{
						type  => 'input_text',
						label => 'Recherche',
						name  => 'q',
						keep_params => [],
					},

					{
						type   => 'input_select',
						name   => 'id_user',
						values => $data -> {users},
						empty  => '[Tout auteur]',
						off    => !$_USER -> {options_hash} -> {support_developer},
					},

					{
						type   => 'input_select',
						name   => 'id_task_status',
						values => $data -> {task_status},
#						off    => !$_USER -> {options_hash} -> {support_developer},
					},

					{
						type    => 'pager',
					},

#					fake_select (),

				],
				
			}

		)
	
}


1;

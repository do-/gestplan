

################################################################################

sub draw_item_of_tasks {

	my ($data) = @_;

	$_REQUEST {__focused_input} = '_label';

	draw_form ({
				
			no_ok => $data -> {fake} <= 0,
			
			additional_buttons => [
			
				{
					icon   => 'folder',
					label  => 'PDF',
					href   => {action => 'print'},
					target => 'invisible',
				},
				
			],
			
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
				name   => 'id_task_severity',
				label  => 'Sévérité',
				type   => 'select',
				values => $data -> {task_severities},
				empty  => '[Veuillez choisir...]',
				read_only => $data -> {fake} <= 0,
			},

			{
				name   => 'id_task_priority',
				label  => 'Priorité',
				type   => 'select',
				values => $data -> {task_priorities},
				empty  => '[Veuillez choisir...]',
				read_only => $data -> {fake} <= 0,
			},

			{
				name   => 'id_task_reproductibility',
				label  => 'Reproductibilité',
				type   => 'select',
				values => $data -> {task_reproductibilities},
				empty  => '[Veuillez choisir...]',
				read_only => $data -> {fake} <= 0,
			},

			{
				name    => 'file',
				label   => 'Fichier',
				type    => 'file',
				size    => 80,
				off     => $data -> {fake} <= 0,
			},

#			{
#				name   => 'id_org',
#				label  => 'Îğãàíèçàöèÿ',
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
#					label => 'Ïî ñêîëüêèì áóêâàì',
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
#						label => 'ñëèòü âûäåëåííûå çàïèñè ñ òåêóùåé',
#						href  => "javaScript:if(confirm('Âû óâåğåíû, ÷òî âñå âûäåëåííûå çàïèñè ñîâïàäàşò ïî ñìûñëó ñ òåêóùåé?')) document.forms ['t1'].submit()",
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
			
			off => !$data -> {actions} || $data -> {fake},
			
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
				label   => 'Message complet',
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
#				label  => 'Ïîëüçîâàòåëü',
#				type   => 'select',
#				values => $data -> {users},
#				empty  => '[Âûáåğèòå ïîëüçîâàòåëÿ]',
#				other  => '/?type=users',
#			},

#			{
#				name   => 'id_org',
#				label  => 'Îğãàíèçàöèÿ',
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
				'Tâche',
				'Auteur',
				'Sévérité',
				'Priorité',
				'Reproductibilité',
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
					$i -> {task_severity} -> {label},
                    $i -> {task_priority} -> {label},
					$i -> {task_reproductibility} -> {label},

				])

			},

			$data -> {tasks},

			{
				
				name => 't1',
				
				title => {label => 'Tâches pour développeurs'},

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
						name   => 'id_task_severity',
						type   => 'input_select',
						values => $data -> {task_severities},
						empty  => '[Toute sévérité]',
					},
		
					{
						name   => 'id_task_priority',
						type   => 'input_select',
						values => $data -> {task_priorities},
						empty  => '[Toute priorité]',
					},
		
					{
						name   => 'id_task_reproductibility',
						type   => 'input_select',
						values => $data -> {task_reproductibilities},
						empty  => '[Toute reproductibilité]',
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

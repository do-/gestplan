

################################################################################

sub draw_task_notes {

	my ($data) = @_;

	return

		draw_table (

			[
				'id',
				'Date',
				'Tвche',
				'Auteur',
				'Message',
				'Fichier',
			],

			sub {
				
				__d ($i, 'dt');

				draw_cells ({
					href => "/?type=tasks&id=$$i{id_task}",
				},[
	
					{
						label  => $i -> {id_task},
						status => $i -> {task_status},
					},
					$i -> {dt},
					$i -> {task} -> {label},
					$i -> {user} -> {label},
					$i -> {label},
					{
						href  => "/?type=task_notes&id=$$i{id}&action=download",
						label => $i -> {file_name},
					},

				])

			},

			$data -> {task_notes},

			{
				
				name => 't1',
				
				title => {label => 'Correspondance'},

#				path => [
#					{name => 'Главная страница', type => 'home_page', id => ''},
#					{name => '...', type => 'task_notes', id => ''},
#				],

				top_toolbar => [{
						keep_params => ['type', 'select'],
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
						off    => !$data -> {users},
					},

					{
						type    => 'pager',
					},

#					fake_select (),

				],
				

			}

		);

}


1;

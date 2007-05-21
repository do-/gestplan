

################################################################################

sub draw_item_of_holydays {


	my ($data) = @_;

	draw_form ({
			right_buttons => [ del ($data) ],
		},
		$data,
		[
			{
				name  => 'dt',
				label => 'Date',
				type  => 'date',
				no_read_only => 1,
			},
			{
				name  => 'is_every_year',
				label => 'Recurrence',
				type  => 'checkbox',
			},
			{
				name  => 'label',
				label => 'Dйsignation',
				size  => 40,
			},
		],
	)

#	.
#
#	draw_table (
#
#		sub {
#		
#			draw_cells ({
#				bgcolor => $i -> {id} == $data -> {id} ? '#ffffd0' : undef,
#			}, [
#				{
#					type => 'checkbox',
#					name => "_clone_$$i{id}",
#					off  => $i -> {id} == $data -> {id} || $i -> {id} == 1,
#				},
#				$i -> {label},
#			]),
#		
#		},
#		
#		$data -> {clones},
#		
#		{
#			
#			title => {label => 'Похожие названия'},
#			
#			off => !$_REQUEST {__read_only} || @{$data -> {clones}} < 2,
#			
#			name => 't1',
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
#						icon    => 'delete',
#						label   => 'слить выделенные записи с текущей',
#						href    => "javaScript:if(confirm('Вы уверены, что все выделенные записи совпадают по смыслу с текущей?'))document.forms['t1'].submit()",
#					}
#				]
#
#			),
#
#		}
#
#	);

}



################################################################################

sub draw_holydays {

	my ($data) = @_;

	return

		draw_table (

#			[
#				'Наименование'
#			],

			sub {
			
				__d ($i, 'dt');

				draw_cells ({
					href  => "/?type=holydays&id=$$i{id}",
				}, [
					$i -> {dt},
					$i -> {label},
				])

			},

			$data -> {holydays},

			{
				title => {label => 'Jours fйriйs'},

				top_toolbar => [{
							keep_params => ['type', 'select'],
						},
					{
						icon    => 'create',
						label   => 'Crйer',
						href    => '?type=holydays&action=create',
					},

					{
						type        => 'input_text',
						icon        => 'tv',
						label       => 'Chercher',
						name        => 'q',
						keep_params => [],
					},

					{
						type    => 'pager',
						cnt     => 0 + @{$data -> {holydays}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},

					$fake_select,

				],
			}
		);

}


1;

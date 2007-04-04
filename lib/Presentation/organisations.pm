################################################################################

sub draw_item_of_organisations {
	
	my ($data) = @_;

	draw_form ({
			right_buttons => [ del ($data) ],
		},
		$data,
		[
			{
				name  => 'label',
				label => 'D�signation',
			},
			{
				name   => 'ids_partners',
				label  => 'Partenaires',
				type   => 'checkboxes',
				values => $data -> {organisations},
			},
			{
				name  => 'href',
				label => 'Menu extra',
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
#			title => {label => '������� ��������'},
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
#					label => '�� �������� ������',
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
#						label   => '����� ���������� ������ � �������',
#						href    => "javaScript:if(confirm('�� �������, ��� ��� ���������� ������ ��������� �� ������ � �������?'))document.forms['t1'].submit()",
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

sub draw_organisations {
	
	my ($data) = @_;

	return

		draw_table (

			sub {

				draw_cells ({
					href  => "/?type=organisations&id=$$i{id}",
				}, [
					$i -> {label},
				])

			},

			$data -> {organisations},

			{
				
				title => {label => 'Missions locales'},

				top_toolbar => [{
							keep_params => ['type', 'select'],
						},
					{
						icon    => 'create',
						label   => 'Cr�er',
						href    => '?type=organisations&action=create',
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
						cnt     => 0 + @{$data -> {organisations}},
						total   => $data -> {cnt},
						portion => $data -> {portion},
					},
				],

				$fake_select,

			},
			
		);

}

1;

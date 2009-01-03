columns => {
	icon    => {TYPE_NAME => 'int'},
	label   => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
},

data => [
	{id => 100, fake => 0, icon => 100, label => 'A faire'},
	{id => 201, fake => 0, icon => 201, label => 'A préciser'},
	{id => 200, fake => 0, icon => 200, label => 'A confirmer'},
	{id => 300, fake => 0, icon => 300, label => 'Confirmé'},
	{id => 301, fake => 0, icon => 301, label => 'Annulé'},
],

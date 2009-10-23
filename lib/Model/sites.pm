columns => {				
	label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	id_organisation => {TYPE_NAME => 'int'},
	ord      => {TYPE_NAME => 'int'},
},

keys => {
	id_organisation => 'id_organisation, ord, label',
},

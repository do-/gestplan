columns => {
	
	id_prestation_type => {TYPE_NAME => 'int'},
	label              => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},

	file_name => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_type => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_path => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
	file_size => {TYPE_NAME    => 'int'},
	
},

keys => {
	id_prestation_type => 'id_prestation_type,label',
},


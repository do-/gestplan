columns => {
	dt              => {TYPE_NAME => 'date'},
	is_every_year   => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEF => 0},
	mmdd            => {TYPE_NAME => 'char', COLUMN_SIZE => 4},
	label           => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	id_organisation => {TYPE_NAME => 'int'},
},

keys => {
	dt   => 'id_organisation,dt',
	mmdd => 'id_organisation,mmdd',
},

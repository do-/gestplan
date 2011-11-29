label => 'Semaines mode\les',

columns => {

	id_organisation          => '(organisations)',
	label                    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	is_odd                   => {TYPE_NAME => 'tinyint', NULLABLE => 0},
	is_auto                  => {TYPE_NAME => 'tinyint', NULLABLE => 0},

},

keys => {
	id_organisation => 'id_organisation,label',
},


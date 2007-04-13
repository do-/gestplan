columns => {				
	id_prestation_type_group => {TYPE_NAME => 'int'},
	id_organisation          => {TYPE_NAME => 'int'},
	color                    => {TYPE_NAME => 'char', COLUMN_SIZE  => 6, NULLABLE => 0, COLUMN_DEFAULT => 'FFFFD0'},
},			

keys => {
	id_prestation_type_group => 'id_prestation_type_group',
},
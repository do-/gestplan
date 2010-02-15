label => 'Partenariats individuels, hors types',

columns => {

	id_organisation         => {TYPE_NAME => 'int'},
	ids_partners 			=> {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	is_open                 => {TYPE_NAME => 'tinyint'},

},

keys => {

	id_organisation => 'id_organisation',
	
},

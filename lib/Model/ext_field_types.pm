columns => {				
	label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	sql_type => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
	max_len  => {TYPE_NAME => 'int'},
	id_organisation => {TYPE_NAME => 'int'},
},

data => [
	{id => 1, fake => 0, label => 'liste',    		sql_type => 'INT',     max_len => 0},
	{id => 2, fake => 0, label => 'numérique',      sql_type => 'DECIMAL', max_len => 254},
	{id => 3, fake => 0, label => 'alphanumérique', sql_type => 'VARCHAR', max_len => 255},
	{id => 4, fake => 0, label => 'logique',        sql_type => 'TINYINT', max_len => 0},
	{id => 5, fake => 0, label => 'long texte',     sql_type => 'TEXT',    max_len => 0},
	{id => 6, fake => 0, label => 'pièce jointe',   sql_type => 'VARCHAR', max_len => 0},
],

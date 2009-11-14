label => 'Onglets',

columns => {				

	label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

	id_organisation => {TYPE_NAME => 'int'},
	
	id_site_group => 'select(site_groups)' # Secteur

},

keys => {

	id_organisation => 'id_organisation, fake, label',
	id_site_group   => 'id_site_group, fake, label',

},

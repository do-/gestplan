label => 'Prestations créées comme invitations',

columns => {

	id_prestation  => '(prestations)',  # La prestation-invitation
	id_inscription => '(inscriptions)', # L'inscription pour laquelle cette prestation est créée

},

keys => {
	id_prestation => 'id_prestation',
},


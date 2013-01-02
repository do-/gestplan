sql (prestation_types => [], sub {

	sql_do ('UPDATE prestation_types SET label_3 = ? WHERE id = ?', (substr $i -> {label_short}, 0, 3), $i -> {id})

});
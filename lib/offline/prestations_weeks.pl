my $st = $db -> prepare ('INSERT INTO prestations_weeks (fake, year, week, id_organisation, id_prestation) VALUES (0, ?, ?, ?, ?)');

sql_select_loop ('SELECT * FROM prestations', sub {

	sql_do ('DELETE FROM prestations_weeks WHERE id_prestation = ?', $i -> {id});

	my ($w, $y) = Week_of_Year (dt_y_m_d ($i -> {dt_start}));

	my ($wf, $yf) = Week_of_Year (dt_y_m_d ($i -> {dt_finish}));
		
	my @prestations_weeks = ();

	while ($y < $yf or ($y == $yf and $w <= $wf)) {
		
		$st -> execute ($y, $w, $i -> {id_organisation}, $i -> {id});

		($w, $y) = Week_of_Year (Add_Delta_Days (Monday_of_Week ($w, $y), 7));
		
	}

});
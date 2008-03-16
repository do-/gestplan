use Date::Calc qw(
	Add_Delta_Days
	Day_of_Week
);

my $holyday = {};

sql_select_loop ('SELECT * FROM holydays WHERE fake = 0',      sub {$holyday -> {$i -> {id_organisation}} -> {$i -> {dt}} = 1});

my $workday = {}; 

sql_select_loop ('SELECT * FROM organisations WHERE fake = 0', sub {$workday -> {$i -> {id}} = {map {$_ => 1} split /\D/, $i -> {days}}});

my $collect = sub {

	my @days = ();
	
	my $day = $i -> {dt_start};

	while ($day le $i -> {dt_finish}) {
	
		my @day = split /-/, $day;
		
		$workday -> {$i -> {id_organisation}} -> {Day_of_Week (@day)} or $holyday -> {$i -> {id_organisation}} -> {$day} ||= 1;
		
		$holyday -> {$i -> {id_organisation}} -> {$day} or push @days, $day;
		
		@day = Add_Delta_Days (@day, 1);
		
		$day = sprintf ('%04d-%02d-%02d', @day);
	
	}
	
	my $cnt = 0;
	
	my $start  = $i -> {dt_start}  . $i -> {half_start};
	my $finish = $i -> {dt_finish} . $i -> {half_finish};
	
	foreach my $day (@days) {
	
		foreach my $half (1, 2) {
		
			$day . $half ge $start  or next;
			$day . $half le $finish or next;
			
			$cnt ++;
			
		}
	
	}
	
	sql_do ('UPDATE prestations SET cnt = ? WHERE id = ?', $cnt, $i -> {id});

};

sql_select_loop (<<EOS, $collect);
	SELECT
		prestations.*
		, prestation_types.id_organisation
	FROM
		prestations
		LEFT JOIN prestation_types ON prestations.id_prestation_type = prestation_types.id
	WHERE
		prestations.fake = 0
EOS

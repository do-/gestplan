
################################################################################

sub select_subset {

	$_USER -> {id} or return {};

	$_REQUEST {__im_delay} = 60 * 1000;
	
	my $href = create_url (); undef $_REQUEST_TO_INHERIT;
		
	js qq {
	
		function try_to_reload (md5) {
			
			\$.getScript ('${href}&__md5=' + md5);
		
		}
	
	};

	return {};

}

1;

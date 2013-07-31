#!/usr/bin/perl
# https://codeiq.jp/ace/yuki_hiroshi/q411

use strict;
use warnings;
use LWP::Simple;

my $start_id   = 5426528869786;
my $deep_id    = 4363616111476;
my $deeper_id  = 5092488161056;
my $deepest_id = 8838746292440;
my @milestone = ($start_id, $deep_id, $deeper_id, $deepest_id);

for (0..$#milestone-1) {
    my %star;                 # $id => ($depth, $from)
    my %unfinished_search;    # $id => ($depth, $finished)
    $star{$milestone[$_]} = '0,-1';
    $unfinished_search{$milestone[$_]} = '0,-1';
    my $max_search = 1;
    my $d = 0;
    my $max_depth = 0;

  NEW_SEARCH: {
      print STDERR "SEARCHING ROUTE ", $milestone[$_], " -> ", $milestone[$_+1],
      " with max_search=", $max_search,  "\n";

      while (!exists($star{$milestone[$_+1]})) {
	  print STDERR "searching d=", $d+1, "\n";

	  foreach my $id (sort keys %unfinished_search) {
	      my ($depth, $finished) = split(/,/, $unfinished_search{$id});
	      if ($depth == $d) {
		  for my $n ($finished+1..$max_search-1) {
		      my $url = 'http://133.242.134.37/deepest.cgi?id='.$id.'&nth='.$n;
		      my $next_id = get($url) or die "Couldn't get URL.";
		      chomp($next_id);
		      if ($next_id) {
			  if (exists($star{$next_id})) {
			      my ($depth_data, $from_data) = split(/,/, $star{$next_id});
			      if ($depth+1 < $depth_data) {
				  print STDERR "  found new route to ", $next_id, " ", $depth+1, ",", $id, "\n";

				  $star{$next_id} = join(',', $depth+1, $id);
				  $unfinished_search{$next_id} = join(',', $depth+1, -1);
			      }
			  } else {
			      print STDERR "  found ", $next_id, " ", $depth+1, ",", $id, "\n";

			      $star{$next_id} = join(',', $depth+1, $id);
			      $unfinished_search{$next_id} = join(',', $depth+1, -1);
			      if ($max_depth < $depth+1) {
				  $max_depth = $depth+1;
			      }
			  }
		      } else {
			  delete($unfinished_search{$id});
			  last;
		      }
		  }
	      }
	  }
	  if ($d >= $max_depth) {
	      print STDERR "STOP: next star was not found.\n";
	      $max_search *= 2;
	      $d = 0;
	      redo NEW_SEARCH;
	  }

	  $d++;
      }
    }

    print STDERR "FOUND ROUTE ", $milestone[$_], " -> ", $milestone[$_+1], " with max_search=", $max_search,  "\n\n";
    print_route($milestone[$_], $milestone[$_+1], %star);
}


sub print_route {
    my ($start, $goal, %star) =@_;
    my @route;
    my $p = $goal;
    unshift(@route, $p);
    do {
	my ($depth, $from) = split(/,/, $star{$p});
	$p = $from;
	unshift(@route, $p);
    } while ($p != $start);

    $| = 1;  # like fflush() in C
    print join(",", @route), "\n";
}


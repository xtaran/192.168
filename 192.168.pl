#!/usr/bin/perl -w

# 192.168.pl -- A more flexible rewrite of Eric Poscher's 192.168.sh
# in Perl See 192.168.epe.at, 192.168.noone.org,
# http://epe.at/de/portfolio/192168epeat and
# http://epe.at/bild/2009/07/192168epeat-im-8-monat

use strict;

use File::Slurp;
use File::Tail;

# Config
my $basedir = "/home/abe/192.168/";
my $remote_host = 'sym.noone.org';
my $remote_user = 'abe';
my $remote_dir = '/home/abe/http/192.168/';
my $remote_force_ipv = '4'; # IPv4

# Files
my $ip_list_file = 'ip-list.txt';
my $header_file  = 'header.html';
my $footer_file  = 'footer.html';
my $output_file  = 'index2.html';

# Find default route

my $default_route_via_dev = `ip r | fgrep 'default via' | awk '{print \$5}'`;
chomp($default_route_via_dev);

unless ($default_route_via_dev) {
    print STDERR "No default route found. Nothing to do.\n";
    exit 0;
}

print "Default IPv4 route goes via $default_route_via_dev.\n";

# Find current IP address

my $ip = `ip addr show $default_route_via_dev | fgrep "inet " | awk '{print \$2}'`;
chomp($ip);
$ip =~ s(/\d+$)();

print "Current IP on $default_route_via_dev is $ip.\n";

if ($ip eq '127.0.0.1') {
    print STDERR "Default route via 127.0.0.1. Nothing to do.\n";
    exit 0;
}

# Now comes all the file handling stuff

chdir($basedir);

# Check if current IP is the same as the last one, and if not, save
# the current IP and generate all the HTML.

my $ip_list_tail = File::Tail->new('name' => $ip_list_file, 'tail' => 1);
my $last_ip = $ip_list_tail->read;
chomp($last_ip);

print "Last known IP was $last_ip.\n";

if ($regenerate_anyway or $last_ip ne $ip) {
    # Append the current IP to the IP list
    write_file($ip_list_file, { append => 1 }, $ip);

    # Generate the HTML
    my $output = read_file($header_file);

    foreach my $ip_from_list (read_file($ip_list_file)) {
	$output .= &make_ip_line($ip_from_list);
    }

    $output .= read_file($footer_file);

    # Save the generated output
    write_file($output_file, $output);
}

# Finally upload the HTML file
&connandcopy();

###
### Functions
###

# Check if we really have a connectio and if so, copy the output to
# the server.
sub connandcopy() {
    if (system(qw(ping -c 1), $remote_host) == 0) {
	system(qw(scp),
	       ($remote_force_ipv ? ("-$remote_force_ipv") : ()),
	       $output_file, "$remote_user\@$remote_host:$remote_dir");
    }
}

# Generate some nice HTML from an IP
sub make_ip_line {
    my $ip = shift;
    my @ip = split(/\./, $ip);

    my $bgcolor = sprintf('#%02X%02X%02X', @ip[0..2]);
    my $fgcolor = sum(@ip[0..2]) > 1.5*255 ? '#000000' : '#ffffff';

    my $style = "background-color: $bgcolor; color: $fgcolor;";

    return qq|<span class="item" style="$style">$ip</span>\n|;
}

sub sum {
    my $result = 0;
    foreach my $value (@_) {
	$result += $value;
    }

    return $result;
}


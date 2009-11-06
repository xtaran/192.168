#!/usr/bin/perl -w

# 192.168.pl -- A more flexible rewrite of Eric Poscher's 192.168.sh
# in Perl See 192.168.epe.at, 192.168.noone.org,
# http://epe.at/de/portfolio/192168epeat and
# http://epe.at/bild/2009/07/192168epeat-im-8-monat
#
# Code © 2009 under GPLv2+ by Axel Beckert <abe@deuxchevaux.org>

use strict;

use File::Slurp;
use File::Tail;

# Config
my $basedir = "/home/abe/192.168/"; # Where is all the data?
my $remote_host = 'sym.noone.org'; # Upload to which host?
my $remote_user = 'abe'; # Upload with which username?
my $remote_dir = '/home/abe/http/192.168/'; # Upload into which directory
my $remote_force_ipv = '4'; # 0 = Don't force, 4 = IPv4, 6 = IPv6
my $regenerate_anyway = 1; # Regenerate even if IP is the same as before?

# Files
my $ip_list_file = 'ip-list.txt';
my $header_file  = 'header.html';
my $footer_file  = 'footer.html';
my $output_file  = 'index.html';

# Find default route

my $default_route = `ip r`;
my $default_route_via_dev = '';

if ($default_route =~ /default via/) {
    my @words = split(/\s+/, $default_route);
    $default_route_via_dev = $words[4];
} elsif ($default_route =~ /default dev/) {
    my @words = split(/\s+/, $default_route);
    $default_route_via_dev = $words[2];
}

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

# First check if IP list file exists. If so check if current IP is the
# same as the last one, and if not, save the current IP and generate
# all the HTML. If it doesn't exist, just create it in the next step

my $last_ip = '';

if (-f $ip_list_file) {
    my $ip_list_tail = File::Tail->new('name' => $ip_list_file, 'tail' => 1);
    $last_ip = $ip_list_tail->read;
    chomp($last_ip);

    print "Last known IP was $last_ip.\n";
}

if ($last_ip ne $ip) {
    # Append the current IP to the IP list
    print "Last known IP ($last_ip) differs from current IP ($ip), so save it.\n";
    write_file($ip_list_file, { append => 1 }, "$ip\n");
}

if ($regenerate_anyway or $last_ip ne $ip) {
    # Generate the HTML
    my $output = read_file($header_file);

    foreach my $ip_from_list (reverse read_file($ip_list_file)) {
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


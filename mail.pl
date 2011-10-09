#! /usr/bin/env perl

=head1 NAME

mail.pl - Fancier mail sender.

=head1 SYNOPSIS

mail.pl [options] [recipients ...]

  Options:
    --help    brief help message
    --man     full documentatin

=cut

use warnings;
use strict;

use Getopt::Long qw(:config no_ignore_case nobundling);
use MIME::Lite;
use MIME::Types qw(by_suffix);
use Data::Dumper;
use File::Basename;
use Carp;
use Pod::Usage;

my $from;
my $subject;
my @bcc;
my @cc;
my @attachments;
my $verbose = '';
my $help = 0;
my $man = 0;

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--subject>

Set the subject of the message

=item B<--from> 

Set the sender of the message

=item B<--bcc>

Add Bcc recipients to the message.

=item B<--cc>

Add Cc recipients to the message.

=item B<--attach>

Add attachments to the message.

=back

=head1 DESCRIPTION

B<mail.pl> will send mail to all recipients passed as arguments.

=cut

GetOptions(
  's|subject=s'         => \$subject,
  'f|from=s'            => \$from,
  'b|bcc-addr=s{,20}'   => \@bcc,
  'c|cc-addr=s{,20}'    => \@cc,
  'a|attach=s{,100}'    => \@attachments,
  'v|verbose'           => \$verbose,
  'h|help'              => \$help,
  'man'                 => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage({ -verbose => 2 }) if $man;

my $to = join(',', @ARGV);

pod2usage(2) unless $to;

my %opts = ();

if ($subject) {
  $opts{Subject} = $subject;
}

if ($from) {
  $opts{From} = $from;
}

if (@bcc) {
  $opts{Bcc} = join(',', @bcc);
}

if (@cc) {
  $opts{Cc} = join(',', @cc);
}

my $data;

{
  local $/;
  $data = <STDIN>;
}

$opts{Data} = $data;

my $msg = MIME::Lite->new(
  %opts
);

# Process the attachments
my $mimetypes = MIME::Types->new;

foreach my $file (@attachments) {
  if (-f $file) {
    my ($mediatype, $encoding) = by_suffix($file);
    print Dumper($mediatype);
    print Dumper($encoding);
    $msg->attach(
      Type      => $mediatype,
      Encoding  => $encoding,
      Path      => $file,
      Filename  => basename($file),
      Disposition => 'attachment',
    );
  }
}

$msg->print;


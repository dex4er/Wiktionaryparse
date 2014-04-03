#!/usr/bin/perl -w

#TODO:Write code, wich will download a latest dump of wikitionary,
#and decompress it to plaintex, command line args handling, also needed

use strict;
use warnings;

use utf8;

use Smart::Comments;

use Data::Dumper;
use XML::Twig;

use IO::Pipe;

my $fhin = IO::Pipe->new->reader(qw(bzip2 -c -d plwiktionary-latest-pages-articles.xml.bz2)) or die "Cannot pipe: $!";
open my $fhout, '>:utf8', 'pokrewne.csv';

# at most one div will be loaded in memory
my $twig=XML::Twig->new(
twig_handlers =>
{
        text => \&text_tag,          # process list elements
},
);

$twig->parse($fhin);

sub text_tag
{
    my ($t, $elem) = @_;

    my ($line,@lines,$title);

    my $text = $elem->text;

    #Check, if given word belongs to the Polish language
    if ($text =~ /^== .* \(\{\{język polski\}\}\) ==/)
    {
            @lines = (split /\n/, $text);
    }
    else
    {
            goto FREE;
    }

    $title = $lines[0];

    while (@lines)
    {
        $line = shift @lines;
        if ($line =~ /^\{\{pokrewne\}\}/)
        {
                $line = shift @lines;
                while ($line =~ /^:/)
                {
                        #Usunięcie niepotrzebnych znaków wokół słowa
                        $title =~ s/== //g;
                        $title =~ s/ ==//g;
                        $title =~ s/\(\{\{język polski\}\}\)//;
                        $title =~ s/\s$//g;
                        $title =~ s/^\s+//;

                        ### $title

                        $line =~ s/:\s*//g;
                        $line =~ s/\{\{.*?\}\}//g;
                        $line =~ s/\[\[(.*?)\]\]/$1,/g;
                        $line =~ s/,+\s*/,/g;
                        $line =~ s/,\s*$//g;
                        $line =~ s/,\/,/,/g;
                        $line =~ s/,,+/,/g;
                        $line =~ s/''.*?''//g;
                        $line =~ s/^\s+//;

                        ### $line

                        if ($line)
                        {
                            print $fhout $title . "," .$line . "\n";
                        }
                        else
                        {
                            print $fhout $title . "\n";
                        }

                        $line = shift @lines;
                }
        }
    }

    FREE: $t->purge;
    return;
}


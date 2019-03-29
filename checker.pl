#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Data::Dumper;

##
# Sprawdza i raportuje dostepnosc sklepow internetowych

use LWP::UserAgent;
use Net::SMTP;
use File::Slurp;

## Ustawienia
my $timestamp = timestamp();
my $fileAlertStatusLog = 'data/alert-status.log';
my $fileStatusLog = 'data/status.log';
my @domains = ('szafyrack.pl', 'wideodomofon-sklep.pl', 'naglosnienie-sklep.pl');

## Zmienne powiadomien email
my $notificationFrom = 'perl@__SERVER_DOMAIN__';
my @notificationTo = ( '' ); ## admin email
my $smtpHost = '127.0.0.1';
my $statusTitle = '';
my $statusBody = '';
my $alertStatus = read_file( $fileAlertStatusLog );

## Bot monitor
my $userAgent = 'Website Monitor Perl Bot v01';
my $ua = LWP::UserAgent->new();
    $ua->show_progress(1);
    $ua->timeout(10);
    $ua->agent( $userAgent );

## Akcja

write_file( $fileStatusLog, {append => 1}, "#---------------------------------------------\n" );

foreach my $domain ( @domains ) {
	my $url = 'http://'. $domain .'/';
	
	#print "[ Sprawdzam domene: $url | ";
	
	my $request = $ua->get( $url );
	
	if ( $request->is_success ) {
	    my $msg = " Sprawdzenie domeny: $url | $timestamp | jest:  -OK- ]\n";
	    #print $msg;
	    write_file( $fileStatusLog, {append => 1}, $msg );
	    
	    
	    #print "[ Sprawdzam: $alertStatus | $domain-1 ]\n";
	    if ( $alertStatus eq $domain.'-1' ) {
		write_file( $fileAlertStatusLog, '' );
	    }
	    
	} else {
	    my $msg = " Sprawdzenie domeny: $url | $timestamp | jest:  -LIPA- ]\n";
	    #print $msg;
	    write_file( $fileStatusLog,{append => 1}, $msg);
	    
	    if ( $alertStatus ne $domain.'-1' ) {
		mailNotification(@notificationTo, $notificationFrom, "Alert dla domeny: ".$domain, $msg);
		write_file( $fileAlertStatusLog, $domain.'-1');
	    }
	    
	}
}

## Funkcje
sub mailNotification {
    ##
    # Wysyla powiadomienie e-mail
    my $mail = $_[0]; # odbiorca
    my $mailFrom = $_[1]; # nadawca
    my $subject = $_[2]; # temat (powinien zawierac komunikat diagnostyczny)
    my $message = $_[3]; # tresc
    my $retval = '0'; # status wykonania

    # Instancja mailera
    my $smtp = Net::SMTP->new( $smtpHost );
    $smtp->mail( $mailFrom );
    $smtp->to( $mail );

    $smtp->data();
    $smtp->datasend("To: ". $mail ."\n");
    $smtp->datasend("Subject: ". $subject ."\n");
    $smtp->datasend("User-Agent: $userAgent\n");
    $smtp->datasend("MIME-Version: 1.0 \nContent-Type: text/plain; charset=us-ascii\n");
    $smtp->datasend("\n");
    $smtp->datasend("\n". $message ."\n");
    $smtp->dataend();
    $retval = $smtp->quit;

    ## TODO Status wysyłki dla mailNotification();

    #$retval = "$mail | $subject | $message ]\n";
    #$retval = "[retval| $status_1 | $status_2 ]\n";
    #print "-> $retval\n";
    return $retval;
}

sub timestamp {
        ##
        # Zwraca znacznik czasu
        my $short = ($_[0]) ? $_[0] : '';
        #print Dumper( $short );

        my ($sec, $min, $hr, $day, $mon, $yr) = localtime;
        my $timestamp = '';

        my $year = 1900 + $yr;
        my $month = $mon + 1;
                $month = sprintf('%02d', $month); #dopisuje zero

        ## Znacznik czasu
        if ( $short eq 'short' ) {
                $timestamp = $year .'-'. $month .'-'. $day;
        } else {
                $timestamp = $year .'-'. $month .'-'. $day .'_'. $hr .'-'. $min .'-'. $sec;
        }


        return $timestamp;
}

## Koniec

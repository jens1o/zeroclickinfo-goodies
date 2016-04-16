package DDG::Goodie::Countdown;

# ABSTRACT: Provides a countdown to a particular date or time

use DDG::Goodie;
with 'DDG::GoodieRole::Dates';

use DateTime;

use strict;

zci answer_type => 'countdown';

zci is_cached => 1;

triggers any => 'countdown to','time until','how long until';

my $datestring_regex = datestring_regex();
my $relative_dates_regex = relative_dates_regex();
my $time_regex = time_12h_regex();
my $output_string;

sub get_initial_difference {
    my $user_input = $_;    
    my $now = DateTime->now(time_zone => _get_timezone());            
    my $then;            
    my $date;
    #user input a combination of time and date string
    my $time = $user_input =~ s/($datestring_regex)//ir;      
    
    #datestring_regex matched somewhere in the input
    if($1) { 
        $then = parse_datestring_to_date($1);                
        $date = $1;   
    }
    
    if($time =~ /($time_regex)/) {
        #create date object and change hr,min,sec of $then       
       print "in time if";
       if(!$then) {            
            $then = DateTime->now(time_zone => _get_timezone());                                 
            $date = $1;
        }
        my ($hours, $minutes, $seconds, $meridiem) = split(/:|[\s]/, $1);
        if($hours == 12) {
            $hours = 0;
        }
        if($meridiem eq 'pm') {
            $hours += 12;
        }    
        if(!($date eq 'tomorrow')) {
            my $new_dur = DateTime::Duration->new(days => 1);                     
            if($then->hour() > $hours || ($then->hour() == $hours and ($then->minute() >= $minutes))) {                        
                $then->add_duration($new_dur);
            }            
        }        
        $then->set_hour($hours);
        $then->set_minute($minutes);
        $then->set_second($seconds);     
    }     
    if(!$then || DateTime->compare($then, $now) != 1) {
        return;
    }       
    my $dur = $then->subtract_datetime_absolute($now);       
    $output_string = date_output_string($then,1);
    return $dur->in_units( 'nanoseconds' );
}


# Handle statement
handle remainder => sub {    
    
    my $initialDifference = get_initial_difference($_);            
        
    return unless $initialDifference;  
    
    return $initialDifference,
        structured_answer => {
            data => {
                remainder => $_,
                difference => $initialDifference,
                countdown_to => $output_string
            },
            templates => {
                group => "text",
            }
        };
};

1;

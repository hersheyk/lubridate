add_duration_to_date <- function(date, duration) {
  if(is.Date(date)){
    date <- as.POSIXct(date)
    ans <- with_tz(.base_add_POSIXt(date, duration), "UTC")
    if (hour(ans) == 0 && minute(ans) == 0 && second(ans) == 0)
      return(as.Date(ans))
    return(ans)
  }
  new <- .base_add_POSIXt(date, duration)
  attr(new, "tzone") <- tz(date)
  reclass_date(new, date)
}

add_duration_to_duration <- function(dur1, dur2)
  make_difftime(as.double(dur1, "secs") + as.double(dur2, "secs"))

add_duration_to_interval <- function(int, dur){
  start <- attr(int, "start")	
  span <- unclass(int) + as.numeric(dur, "secs")
  new_interval(start + span, start)
}

add_duration_to_period <- function(per, dur){
	message("duration converted to seconds")
	per + seconds(as.numeric(dur, "secs"))
}



add_interval_to_date <- function(date, interval){
	if (any(attr(interval, "start") != as.POSIXct(date)))
	   message("coercing interval to duration")
	   dur <- as.duration(interval)
	   attr(dur, "start") <- NULL
	add_duration_to_date(date, dur)
}

add_interval_to_interval <- function(int1, int2){
	start1 <- attr(int1, "start")
	start2 <- attr(int2, "start")
	end1 <- start1 + int1
	end2 <- start2 + int2
	
	if(all(start2 == end1))
		return(new_interval(start1 + int1 + int2, start1))
	else if (all(start1 == end2))
		return(new_interval(start2 + int2 + int1, start2))
	else if (all(start1 == start2))
		return(as.interval(start1, pmax(end1, end2)))
	
	message("Intervals do not align: coercing to durations")
	dur <- as.duration(int1) + as.duration(int2)
	attr(dur, "start") <- NULL
	dur
}



add_number_to_date <- function(e1, e2)
      structure(unclass(e1) + e2, class = "Date")

add_number_to_duration <- function(dur, num){
	if (is.difftime(dur))
		return(make_difftime(num + as.double(dur, "secs")))
  	new_duration(num + unclass(dur))
}

add_number_to_interval <-function(int, num){
  message("numeric coerced to duration in seconds")
  add_duration_to_interval(int, as.duration(num))
}

add_number_to_period <- function(per, num){
  message("numeric coerced to seconds")
  per$second <- per$second + num
  per
}

add_number_to_posix <- function(e1, e2){
      if(is.POSIXct(e1)){
      	return(structure(unclass(as.POSIXct(e1)) + e2, class = 
      		class(e1)))
      }
      as.POSIXlt(structure(unclass(as.POSIXct(e1)) + e2, class = 		class(as.POSIXct(e1))))
}



add_period_to_date <- function(date, period){
	new <- update(as.POSIXlt(date), 
			years = year(date) + period$year,
			months = month(date) + period$month,
			days = mday(date) + period$day,
			hours = hour(date) + period$hour,
			minutes = minute(date) + period$minute,
			seconds = second(date) + period$second
			)
	if (is.Date(date) && sum(new$sec, new$min, new$hour, na.rm = TRUE) != 0)
	return(new)	
	
	reclass_date(new, date)
}

add_period_to_interval <- function(int, per){
  start <- attr(int, "start")
  end <- start + unclass(int)
  end2 <- end + per
  new_interval(end2, start)
}

add_period_to_period <- function(per1, per2){
  to.add <- suppressWarnings(cbind(per1,per2))
  structure(to.add[,1:6] + to.add[,7:12], class = c("period", "data.frame"))
}



add_dates <- function(e1, e2){
  
  if (is.instant(e1)) {
    if (is.instant(e2))
      stop("binary '+' not defined for adding dates together")
    if (is.period(e2))
      add_period_to_date(e1, e2)
    else if (is.interval(e2))
      add_interval_to_date(e1, e2)
    else if (is.difftime(e2)) 
      add_duration_to_date(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_date(e1, e2)
    else if (is.POSIXt(e1))
      add_number_to_posix(e1, e2)
    else if (is.Date(e1))
      add_number_to_date(e1, e2)
    else{
      base::'+'(e1,e2)
      }
  }

  else if (is.period(e1)) {
    if (is.instant(e2))
      add_period_to_date(e2, e1)
    else if (is.period(e2))
      add_period_to_period(e1, e2)
    else if (is.interval(e2))
      add_period_to_interval(e2, e1)
    else if (is.difftime(e2))
      add_duration_to_period(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_period(e1, e2)
    else
      add_number_to_period(e1, e2)
  }
  
  else if (is.interval(e1)){
    if (is.instant(e2))
      add_interval_to_date(e2, e1)
    else if (is.interval(e2))
      add_interval_to_interval(e1, e2)
    else if (is.period(e2))
      add_period_to_interval(e1, e2)
    else if (is.difftime(e2))
      add_duration_to_interval(e1, e2) 
    else if (is.duration(e2)) 
      add_duration_to_interval(e1, e2) 
    else
      add_number_to_interval(e1, e2)
  }

  else if (is.difftime(e1)) {
    if (is.instant(e2))
      add_duration_to_date(e2, e1)
    else if (is.period(e2))
      add_duration_to_period(e2, e1)
    else if (is.interval(e2))
      add_duration_to_interval(e2, e1)
    else if (is.difftime(e2))
      add_duration_to_duration(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_duration(e1, e2)
    else
      add_number_to_duration(e1, e2)
  }
  
    else if (is.duration(e1)) {
    if (is.instant(e2))
      add_duration_to_date(e2, e1)
    else if (is.period(e2))
      add_duration_to_period(e2, e1)
    else if (is.interval(e2))
      add_duration_to_interval(e2, e1)
    else if (is.difftime(e2))
      add_duration_to_duration(e1, e2)
    else if (is.duration(e2)) 
      add_duration_to_duration(e1, e2)
    else
      add_number_to_duration(e1, e2)
  }
  
  else if (is.numeric(e1)) {
    if (is.POSIXt(e2))
      add_number_to_posix(e2, e1)
    else if (is.Date(e1))
      add_number_to_date(e2, e1)
    else if (is.period(e2))
      add_number_to_period(e2, e1)
    else if (is.interval(e2))
      add_number_to_interval(e2, e1) 
    else if (is.difftime(e2))
      add_number_to_duration(e2, e1) 
    else stop("Unknown object class")
  }
  else stop("Unknown object class")
}


#' Makes a difftime object from a given number of seconds 
#'
#' @export make_difftime
#' @param x number value of seconds to be transformed into a difftime object
#' @return a difftime object corresponding to x seconds
#' @keywords chron
#' @examples
#' make_difftime(1)
#' make_difftime(60)
#' make_difftime(3600)
make_difftime <- function (x) {  
  seconds <- abs(x)
    if (any(seconds < 60)) 
        units <- "secs"
    else if (any(seconds < 3600))
        units <- "mins"
    else if (any(seconds < 86400))
        units <- "hours"
    else
        units <- "days"

    
    switch(units, secs = structure(x, units = "secs", class = "difftime"), 
      mins = structure(x/60, units = "mins", class = "difftime"), 
      hours = structure(x/3600, units = "hours", class = "difftime"), 
      days = structure(x/86400, units = "days", class = "difftime"))
}

multiply_duration_by_number <- function(dur, num)
	structure(as.numeric(dur) * num, class = c("duration", "numeric"))



multiply_period_by_number <- function(per, num){
  new_period(
    year = per$year * num,
    month = per$month * num,
    day = per$day * num,
    hour = per$hour * num,
    minute = per$minute * num,
    second = per$second * num
  )
}

multiply_interval_by_number <- function(int, num){
	start <- attr(int, "start")
	span <- num * as.duration(int)
	
	new_interval(start + span, start)
}



"*.period" <- "*.interval" <- "*.duration" <- function(e1, e2){
    if (is.timespan(e1) && is.timespan(e2)) 
      stop("cannot multiply time span by time span")
    else if (is.period(e1))
      multiply_period_by_number(e1, e2)
    else if (is.period(e2))
      multiply_period_by_number(e2, e1)
    else if (is.interval(e1))
      multiply_interval_by_number(e1, e2)
    else if (is.interval(e2))
      multiply_interval_by_number(e2, e1)
    else if (is.duration(e1))
      multiply_duration_by_number(e1, e2)
    else if (is.duration(e2))
      multiply_duration_by_number(e2, e1)
    else base::'*'(e1, e2)
}  



divide_duration_by_difftime <- function(dur, diff)
	as.numeric(dur) / as.numeric(diff, units = "secs")

divide_duration_by_duration <- function(dur1, dur2)
	as.numeric(dur1) / as.numeric(dur2)
	
divide_duration_by_interval <- function(dur, int)
	as.numeric(dur) / as.numeric(int)

divide_duration_by_number <- function(dur, num)
	new_duration(as.numeric(dur) / num)

divide_duration_by_period <- function(dur, per)
	as.numeric(dur) / as.numeric(as.duration(per))


divide_interval_by_difftime <- function(int, diff){
	as.numeric(unclass(int) / as.double(diff, units = "secs"))
}

divide_interval_by_duration <- function(int, dur){
	as.numeric(unclass(int) / unclass(dur))
}

divide_interval_by_interval <- function(int, dur){
	as.numeric(unclass(int) / unclass(int))
}

divide_interval_by_number <- function(int, num){
	start <- attr(int, "start")
	span <- as.duration(int) / num
	
	new_interval(start + span, start)
}

equalize_length <- function(x, y){
	n.x <- length(x)
	n.y <- nrow(y) 
	n.max <- max(n.x, n.y)
	n.min <- min(n.x, n.y)
	if (n.max %% n.min != 0L){
		stop("longer object length is not a multiple of shorter object length")
	} else {
		if (n.x < n.y) {
			x <- rep(x, length.out = n.y)
		} else {
			y <- rep(y, length.out = n.x)
		}	
	}
	list(x, y)
}

divide_interval_by_period <- function(int, per){
	
	equals <- equalize_length(int, per)
	int <- equals[[1]]
	per <- equals[[2]]
	
	paired.up <- data.frame(interval = int, per, row = seq_along(int))

	
	division_engine <- function(df){
		int <- df$int
		per <- structure(df[,2:7], class = c("period", "data.frame"))
	
		start <- attr(int, "start")
		end <- start + unclass(int)
	
		# sign of period shouldn't affect answer
		per <- abs(per)
	
		# duration division should give good approximation
		dur <- suppressMessages(as.duration(per))
		estimate <- trunc(as.numeric(int) / as.numeric(dur))
	
		# did we overshoot or undershoot?
		try1 <- start + per * estimate
		miss <- as.numeric(end) - as.numeric(try1)
	
		# adjust estimate until satisfactory
		n <- 0
		if (miss == 0) {
			return(estimate)
		} else if (miss > 0) {
			while (try1 + n * per < end)
				n <- n + 1
			# because the last one went too far	
			return(estimate + (n - 1)) 
		} else {
			while (try1 - n * per > end)
				n <- n + 1
			# because the last one went too far	
			return(estimate - (n + 1))
		}
	}
	
	unlist(ddply(paired.up, "row", division_engine)[,2])	
}


divide_period_by_difftime <- function(per, diff){
	as.numeric(as.duration(per)) / as.numeric(diff, units = "secs")
}


divide_period_by_duration <- function(per, dur){
	as.numeric(as.duration(per)) / as.numeric(dur)
}

divide_period_by_interval <- function(per, int){
	as.numeric(as.duration(per)) / as.numeric(int)
}

divide_period_by_number <- function(per, num){
  new_period(
    year = per$year / num,
    month = per$month / num,
    day = per$day / num,
    hour = per$hour / num,
    minute = per$minute / num,
    second = per$second / num
  )
}

divide_period_by_period <- function(per1, per2){
	suppressMessages(as.duration(per1)) / as.duration(per2)
}


	
"/.period" <- "/.interval" <- "/.duration" <- function(e1, e2){
    if (is.interval(e1)) {
    	if (is.duration(e2))
    		divide_interval_by_duration(e1, e2)
    	else if (is.difftime(e2))
    		divide_interval_by_difftime(e1, e2)
    	else if (is.interval(e2))
    		divide_interval_by_interval(e1, e2)
    	else if (is.period(e2))
    		divide_interval_by_period(e1, e2)
    	else if (is.numeric(e2))
    		divide_interval_by_number(e1, e2)
    } else if (is.duration(e1)) {
    	if (is.duration(e2))
    		divide_duration_by_duration(e1, e2)
    	else if (is.difftime(e2))
    		divide_duration_by_difftime(e1, e2)
    	else if (is.interval(e2))
    		divide_duration_by_interval(e1, e2)
    	else if (is.period(e2))
    		divide_duration_by_period(e1, e2)
    	else if (is.numeric(e2))
    		divide_duration_by_number(e1, e2)
    } else if (is.period(e1)) {
    	if (is.duration(e2))
    		divide_period_by_duration(e1, e2)
    	else if (is.difftime(e2))
    		divide_period_by_difftime(e1, e2)
    	else if (is.interval(e2))
    		divide_period_by_interval(e1, e2)
    	else if (is.period(e2))
    		divide_period_by_period(e1, e2)
    	else if (is.numeric(e2))
    		divide_period_by_number(e1, e2)
    }   else base::'/'(e1, e2)
}  


subtract_interval_from_date <- function(int, date){
	end <- attr(int, "start") + unclass(int)
	if (any(end != as.POSIXct(date)))
	   message("interval does not align: coercing to duration")
	dur <- as.duration(int)
	attr(dur, "start") <- NULL
	add_duration_to_date(date, -dur)
}

subtract_interval_from_interval <- function(int2, int1){
	start1 <- attr(int1, "start")
	start2 <- attr(int2, "start")
	end1 <- start1 + int1
	end2 <- start2 + int2
	
	if (all(end1 >= end2)){
		if (all(end2 == end1))
			return(new_interval(start2, start1))
		else if (all(start2 == start1))
			return(new_interval(end2, end1))
	}
	
	message("Intervals do not align: coercing to durations")
	dur <- as.duration(int1) - as.duration(int2)
	attr(dur, "start") <- NULL
	dur
}

subtract_dates <- function(e1, e2){
  if (missing(e2))
    -1 * e1
  else if(is.instant(e1) && is.instant(e2))
    new_interval(e2, e1)
  else if (is.POSIXct(e1) && !is.timespan(e2))
    structure(unclass(e1) - e2, class = class(e1))
  else if (is.POSIXlt(e1) && !is.timespan(e2)){
    as.POSIXlt(structure(unclass(as.POSIXct(e1)) - e2, 
    	class = class(as.POSIXct(e1))))
  } else if (is.interval(e1) && is.interval(e2))
  	subtract_interval_from_interval(e2, e1)
  else if (is.instant(e1) && is.interval(e2))
  	subtract_interval_from_date(e2, e1)
  else if (is.interval(e2)){
  	message("undefined use of interval: coercing to duration")
  	e2 <- as.duration(e2)
  	attr(e2, "start") <- NULL
  	e1  + (-1 * e2)
  } else
    e1  + (-1 * e2)
}








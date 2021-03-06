## TODO: large gaps in data result in some strange-looking polygons

## TODO: 'id' isn't a very safe argument for defining profile IDs... (e.g. sp1)

## TODO: iterate over profile IDs instead of groups
# note: confidence bands not defined when NA is present
panel.depth_function <- function(x, y, id, upper=NA, lower=NA, subscripts=NULL, groups=NULL, sync.colors=FALSE, cf=NA, cf.col=NA, cf.interval=20, ...) {
  
# add grid
panel.grid(h=-1, v=-1, lty=3, col=1)

# load current line style
superpose.line <- trellis.par.get("superpose.line")

# TODO: add uncertainty viz.
# when the length of 'y' is > 'x', we are plotting a step function
if(length(y) > length(x)) {
  if(missing(id))
    stop('must provide a profile id')
  
  message('plotting segments...')
  
  # re-make a nice dataframe, assuming that we have 'groups' defined
  if(!missing(groups)) {
    d <- data.frame(prop=x, bnd=y, upper=upper[subscripts], lower=lower[subscripts], groups=groups[subscripts], id=id[subscripts])
  } else {
    # 'groups' is missing, add a fake 'groups' column
    d <- data.frame(prop=x, bnd=y, upper=upper[subscripts], lower=lower[subscripts], groups=factor(1), id=id[subscripts])
  }
  
  
  # add line segments that form step-function
  ## TODO: iterate over profile IDs instead of groups
  by(d, d$id, make.segments, ...)	
	}

# normal plot -- not a step function
else {
	# if we have an upper and lower bound defined, plot them
	if(!missing(upper) & !missing(lower)) {
		# working with grouped data and paneled data
		if(!missing(groups) & !missing(subscripts)) {
			d <- data.frame(yhat=x, top=y, upper=upper[subscripts], lower=lower[subscripts], groups=groups[subscripts])
			# levels in the groups, for color matching
			ll <- levels(d$groups)
			n_groups <- length(ll)
			}
		
		# no grouping, add a fake group for compatiblity
		if(missing(groups)) {
		  fake.groups <- factor(1)
			d <- data.frame(yhat=x, top=y, upper=upper[subscripts], lower=lower[subscripts], groups=fake.groups)
			
			# levels in the groups, for color matching
			ll <- levels(d$groups)
			n_groups <- length(ll)
			}
		
    # optionally sync region + main line colors
    if(sync.colors)
      region.col <- rep(superpose.line$col, length.out=n_groups)
    else
      region.col <- rep(grey(0.7), length.out=n_groups)
      
		# add conf. intervals / aggregation uncertainty
		by(d, d$groups, function(d_i) {
      # lookup color
  	  m <- match(unique(d_i$group), ll)
      
			# cannot have NA in values that define polygon boundaries
  	  d_i <- d_i[which(!is.na(d_i$upper) & !is.na(d_i$lower)), ]
			
			# make conf.int polygon
			panel.polygon(x=c(d_i$lower, rev(d_i$upper)), y=c(d_i$top, rev(d_i$top)), col=region.col[m], border=NA, ...)
			})
		}
	
	# no upper/lower polygon boundaries defined
	else {
	  if(missing(groups)) {
	    fake.groups <- factor(1)
	    d <- data.frame(yhat=x, top=y, groups=fake.groups)
	  } else {
	    d <- data.frame(yhat=x, top=y, groups=groups[subscripts]) 
	  }
		
		# levels in the groups, for color matching
		ll <- levels(d$groups)	
		n_groups <- length(ll)
		}
	
  # setup style parameters for main lines 
  # repeat enough times for the current number of groups
  line.col <- rep(superpose.line$col, length.out=n_groups)
	line.lty <- rep(superpose.line$lty, length.out=n_groups)
	line.lwd <- rep(superpose.line$lwd, length.out=n_groups)
	
	# add main lines
	by(d, d$groups, function(d_i){
		# lookup color
		m <- match(unique(d_i$group), ll)

		# add line
		panel.lines(d_i$yhat, d_i$top, lwd=line.lwd[m], col=line.col[m], lty=line.lty[m])
		})
	}

	
  # annotate with contributing fraction
  if(!missing(cf)) {
		
  	# add CF data to panel's worth of data
  	d$cf <- cf[subscripts]
  	
  	# annotate with contributing fraction by group
  	by(d, d$groups, function(d_i){
  		  		
  		# lookup linestyle by group
  		m <- match(unique(d_i$group), ll)
  		
  		# if there is no user-specified CF color, then use the same as line style
  		if(is.na(cf.col)) {
  			cf.col <- line.col[m]
  		}
  		
  		# make a function for linear interpolation of CF values based on depth
  		cf.approx.fun <- approxfun(d_i$top, d_i$cf, method='linear')
  		
  		# generate annotated depths: 5 cm to 95th percentile of max depth
  		y.q95 <- quantile(d_i$top, probs=c(0.95), na.rm=TRUE)
  		a.seq <- seq(from=2, to=y.q95, by=cf.interval)
  		
  		# offset CF sequence according to group index
  		a.seq <- a.seq + ((m-1) * cf.interval/4)
  		
  		# interpolate CF at annotated depths
  		a.CF <- cf.approx.fun(a.seq)
  		a.text <- paste(round(a.CF * 100), '%')
      
      # remove any NAs in CF sequence and text
      not.na.idx <- which(! is.na(a.CF))
      a.seq <- a.seq[not.na.idx]
      a.text <- a.text[not.na.idx]
  		
  		# add to right-hand side of the panel
  		unit <- gpar <- NULL
  		grid.text(a.text, x=unit(0.99, 'npc'), y=unit(a.seq, 'native'), just='right', gp=gpar(font=3, cex=0.8, col=cf.col))
  	})
      
  }

}


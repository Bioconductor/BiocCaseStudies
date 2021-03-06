## parse package information from the Suggests field
parseLibVers <- function(){
  sug <- gsub("\n", "", packageDescription("BiocCaseStudies")$Suggests)
  tmp <- unlist(strsplit(sug, ","))
  res <- data.frame(package=I(gsub("^ | ?[(].*", "", tmp)),
                    version=I(gsub(">= ?|)", "", sapply(strsplit(tmp, "(",
                      fixed=TRUE), function(x) x[2]))))
  return(res)
}


## check for missing and outdated packages
requiredPackages <- function(load=FALSE){
  ## get package information
  cat("checking for package dependencies...\n")
  oldOpt <- options(warn=-1)
  reqPck <- parseLibVers()
  avPck <- lapply(reqPck$package, function(x){
                pd <- packageDescription(x)
                if(is(pd, "packageDescription"))
                  packageDescription(x)$Version
                else
                  NULL})
  names(avPck) <- reqPck$package
  ## find missing packages
  missing <- sapply(avPck, is.null)
  if(any(missing)){
    file.remove("useRbook.tex")
    stop("Please install the following package(s) to build the book:\n  ",
         paste(unlist(reqPck$package[missing]), "\n  "), call.=FALSE)
  }
  ## continue only with packages for which version is specified
  sel <- !missing & !is.na(reqPck$version)
  avPck <- unlist(avPck[sel])
  ## find outdated packages
  #outdated <- mapply(">", reqPck[sel, "version"], avPck)
  outdated <- mapply(function(x,y) package_version(x) > package_version(y),
                     reqPck[sel, "version"], avPck)
  if(any(outdated)){
    file.remove("useRbook.tex")
    stop("The following package(s) need(s) to be updated\n",
         "in order to build the book:\n  ",
         paste(unlist(names(avPck)[outdated]), "(is", avPck[outdated] ,
               "should be",  reqPck[sel, "version"][outdated],
               ")\n  "), call.=FALSE)
   }
  options(oldOpt)
  cat("Great!!! All packages are up to date\n")

  if(load){
      loadRes <- list()
      for(p in reqPck[,1])
          loadRes[[p]] <- try(eval(parse(text=paste("library(", p, ")",
                                         sep=""))), silent=TRUE)
      err <- sapply(loadRes, function(x) is(x, "try-error"))
      if(any(err))
          stop("The following package(s) could not be loaded:\n",
               paste(names(loadRes[err]), collapse=", ", sep=""))
      else(message("All packages loaded successfully"))
  }
  return(invisible(NULL))
}

packages2install = function(){
  ## get package information
  reqPck = parseLibVers()
  avPck = lapply(reqPck$package, function(x){
                pd = packageDescription(x)
                if(is(pd, "packageDescription"))
                  packageDescription(x)$Version
                else
                  NULL})
  names(avPck) = reqPck$package

  ## find missing packages
  missing = sapply(avPck, is.null)
  s1 = if(any(missing)) unlist(reqPck$package[missing]) else character(0)

  ## find outdated packages
  sel = !missing & !is.na(reqPck$version)
  avPck = unlist(avPck[sel])
  outdated = mapply(function(x,y) package_version(x) > package_version(y),
                     reqPck[sel, "version"], avPck)

  
  s2 = if(any(outdated)) unlist(names(avPck)[outdated]) else character(0)

  return(c(s1, s2))
}

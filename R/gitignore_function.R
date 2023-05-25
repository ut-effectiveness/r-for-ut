# this appends whatever you want to the .gitignore file 
# note: you need to have \n before the object to create a new line.
#cat("\n*.html\nsensitive/*", file = here::here(".gitignore"), sep = "\n", append = TRUE)

add_to_gitignore <- function() {
  
  x <- grep("sensitive/*", readLines(here::here(".gitignore")))
  
  if (length(x) < 1)  {
    
    cat("*.html\nsensitive/*", file = here::here(".gitignore"), sep = "\n", append = TRUE)
    
  } else {
    
    cat("already exists")
    
  }
}

add_to_gitignore()

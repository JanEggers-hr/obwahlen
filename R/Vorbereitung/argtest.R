library(pacman)

# Laden und ggf. installieren
p_load(this.path)
p_load(R.utils)
rm(list=ls())

# Lies Parameter: 
# - Verzeichnis (aus dem auch die )

# Argumente werden in einem String-Vektor namens args übergeben,
# wenn ein Argument übergeben wurde, dort suchen, sonst Unterverzeichnis "src"

cat("Parameter: --TEST für Test, ",
    "--DO_PREPARE_MAPS für Switcher-Generierung, ",
    "wahl_name=<Verzeichnisname>\n\n")

#   list(R=NA, DATAPATH="../data" args=TRUE, root="do da",
#        foo="bar", details=TRUE, a="2")

args = commandArgs(asValues = TRUE)
if (length(args)!=0) { 
  TEST <- "TEST" %in% names(args)
  DO_PREPARE_MAPS <- "DO_PREPARE_MAPS" %in% names(args)
  if ("wahl_name" %in% names(args)) {
    wahl_name <- args[["wahl_name"]]
    if (!dir.exists(paste0("index/",wahl_name))) stop("Kein Index-Verzeichnis für ",wahl_name)
  }
} 


if (!exists("TEST")) TEST = FALSE
if (!exists("DO_PREPARE_MAPS")) DO_PREPARE_MAPS = FALSE

print(args)
print(TEST)
print(DO_PREPARE_MAPS)
print(wahl_name)

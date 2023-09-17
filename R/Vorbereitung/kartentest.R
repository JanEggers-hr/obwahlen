require(lubridate)
require(DatawRappr)
require(tidyr)
require(dplyr)
require(readr)

test_id <- "llDXC"


# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# testdaten <- read_csv(paste0("data-",test_id,".csv")) %>% 
#     mutate(kand1 = runif(nrow(.),1,30))

# Wird alle 15min aufgerufen
# dw_data_to_chart(testdaten,test_id)
# dw_edit_chart(test_id,title=paste0("TEST ",now()))
# dw_publish_chart(test_id)
# cat("Testdaten erfolgreich auf ",test_id," geschrieben")
# 
kandnamen <- c("Becker (CDU)",
               "Josef (SPD)",
               "Rottmann (Grüne)",
               "Wirth (unabh.)",
               "Mehler-Würzbach (Linke)")

testdaten2 <- tibble(`Kandidat/in` = kandnamen, 
                     Stimmenanteil = round(runif(5,5,30),5))

test_id <- "Gsg8E"

write_csv(testdaten2,"testdaten2.csv")
# dw_data_to_chart(testdaten2,test_id)
system('gsutil -h "Cache-Control:no-cache, max_age=0" cp testdaten2.csv gs://d.data.gcp.cloud.hr.de/testdaten2.csv')
dw_edit_chart(test_id,title=paste0("TEST ",now()))
dw_publish_chart(test_id)
cat("Testdaten erfolgreich auf ",test_id," geschrieben")

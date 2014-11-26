Summarize Flattr Reports
---
R script to create summary CSV files and diagrams from Flattr's Monthly Revenue reports.

Usage Instructions
---
1. In [your "Transactions"-list on Flattr](https://flattr.com/dashboard/transactions), open each "Monthly revenue"-report, click "Download as CSV"and save them to a folder of your choice.
1. Download [this script](https://github.com/KonScience/Summarise-Flattr-Reports/blob/master/summarise-flattr-reports.R) to the same or any other folder.
1. Download [RStudio](http://www.rstudio.com/products/rstudio/download/) and install.
1. Open the script (.r file) in RStudio and run it with `alt+CMD+R` (should take just a few seconds) and find the newly generated files in the same folder as the .csv files you downloaded from Flattr.
1. Please contribute ideas, criticism and code, by [opening an issue](https://github.com/KonScience/Summarize-Flattr-Reports/issues/new) or [forking](https://github.com/KonScience/Summarize-Flattr-Reports/fork) and sending a pull request.

Ideas
---
- ~~sort data usefully~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/pull/1)
- simplify data input (~~better file/folder selection~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/c4b8f15d4d0bdb8001b3a7255bb71077e76b8638), or automatic download from flattr.com)
  - also read out withdrawals & draw Flattr "balance" diagram
- draw more useful diagrams
  - ~~coloration of datapoints per Flattr thing~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/1e5ddef18fa89015688f3b9d3dc30db35c2b8652?diff=unified#diff-aecf3d2d8db8e5ca05c6f01653041e00L68)
  - ~~auto-determine useful diagram dimensions~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/3ad233725442802cebed5d4b0d8aea757a002fed)
  - improve visualisation for very large datasets
  - ~~merge bubble & scatter plots into single diagram~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/4f5f6011f8ace2f92d7e3bd47a65ad4922c586b0)
- summarise Flattr clicks per month, not ordered by thing
- predictions (anybody knows the statistics behind this?)
- episodes vs. other things (probably needs reg-ex on slugs)
- webapp via Shiny that processes given data for a Flattr-click
- install on server to auto-run & publish diagram 

Thanks and Greetings :-)
---
- Dr. Rick Scavetta of [Science Craft](http://www.science-craft.com/) and  [Konstanz Graduate School Chemical Biology](http://www.chembiol.uni-konstanz.de/) for the Data Analysis course
- [RegExr](http://www.regexr.com/) for help with finding regular expression
- [R-help Archives](https://stat.ethz.ch/pipermail/r-help/) of the ETH Zürich's [Seminar For Statistics](https://stat.ethz.ch/)

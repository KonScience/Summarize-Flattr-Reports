Summarize Flattr Reports
---
R script to create summary CSV files and diagrams from Flattr's Monthly Revenue reports. [Example here](http://www.konscience.de/uber-uns/#flattr-auswertung). You can also flattr this repo:

[![Flattr Button](https://api.flattr.com/button/flattr-badge-large.png "Flattr This!")](http://flattr.com/thing/3665103/KonScienceSummarize-Flattr-Reports-on-GitHub "Summarize-Flattr_Reports")  
[![Build Status](https://travis-ci.org/SimonWaldherr/Summarize-Flattr-Reports.svg?branch=master)](https://travis-ci.org/SimonWaldherr/Summarize-Flattr-Reports)  

Usage Instructions
---
1. Download and install both [RStudio](https://www.rstudio.com/products/rstudio/download/) and [R](https://cran.rstudio.com/).
1. Go to [your Flattr Transactions](https://flattr.com/dashboard/transactions).
  1. Open each "Monthly revenue"-report (or start with only a few).
  1. Click "Download as CSV" below the table of Things.
  1. Save them to a folder of your choice.
1. Download [this repository](https://github.com/KonScience/Summarize-Flattr-Reports/archive/master.zip) to the same or any other folder and unpack the .zip.
  1. Open RStudio, copy-paste this command `install.packages(c("plyr", "ggplot2", "scales"))` into the console (bottom left) and run it by pressing `Return/Enter`. Some progress of new packages being installed should be visible. If an error is shown instead, copy-paste the error message into a search engine you don't completely distrust.
  1. Once these packages are installed, open the script (.r file) in RStudio and run it with `alt + cmd + R` (Mac) or `ctrl + alt + R` (Win).
  1. Follow its progress in RStudios' `Console` and `Plot` tabs. This may take few seconds to several minutes, depending on your number of Flattr Revenue Reports, data points in them, and the speed of your computer. Example: 20 Reports with 200 data points at [2.3 GHz](http://www.everymac.com/systems/apple/macbook_pro/specs/macbook-pro-core-i5-2.3-13-early-2011-unibody-thunderbolt-specs.html): 10-20sec.
  1. Find the newly generated .csv files and .png diagrams in the same folder as the .csv files you downloaded from Flattr.
1. Please [report back](https://github.com/KonScience/Summarize-Flattr-Reports/issues/new) :-) Are the diagrams useful? If not, at which dataset size? Which other summaries, calculations or diagrams would you find useful?

Ideas
---
- [x] sort data usefully [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/pull/1)
- [x] better file/folder selection [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/c4b8f15d4d0bdb8001b3a7255bb71077e76b8638)
- [ ] automatic download from flattr.com, including withdrawals & deposits
- draw more useful diagrams
  - [x] coloration of datapoints per Flattr thing [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/1e5ddef18fa89015688f3b9d3dc30db35c2b8652?diff=unified#diff-aecf3d2d8db8e5ca05c6f01653041e00L68)
  - [x] auto-determine useful diagram dimensions [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/3ad233725442802cebed5d4b0d8aea757a002fed)
  - [x] merge bubble & scatter plots into single diagram  [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/4f5f6011f8ace2f92d7e3bd47a65ad4922c586b0)
  - [ ] improve visualisation for very large datasets
- [x] summarise Flattr clicks per month, not ordered by thing [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/000f9f18bba90586aa47155dbdcea4448680fff9)
- [ ] predictions (anybody knows the statistics behind this?)
- [ ] episodes vs. other things (probably needs reg-ex on slugs)
- [ ] webapp via Shiny that processes given data ~~for a Flattr-click~~ [Not a good idea](https://stackoverflow.com/questions/8971918/using-flattr-as-paywall)
- [ ] install on server to auto-run & publish diagram

Known Issues
---
- monthly_simple_plot contains statistical elements whose computation runs into errors if the number of Flattr Revenue Reports is below 5. Other graphs may also throw warnings. To avoid this while plotting such small datasets, insert `#` before any line with `stat_`. Better yet: [download more Revenue Reports, see `2.`](https://github.com/KonScience/Summarize-Flattr-Reports#usage-instructions)

Contribution Guidelines
---
I try to follow the [gitflow branching model](http://nvie.com/posts/a-successful-git-branching-model)/. Therefore, please branch off `develop` whenever possible, give the new branch a descriptive name and merge it back into `develop`. 

Thanks and Greetings :-)
---
- Dr. Rick Scavetta of [Science Craft](http://www.science-craft.com/) and  [Konstanz Graduate School Chemical Biology](http://www.chembiol.uni-konstanz.de/) for the Data Analysis course
- [RegExr](http://www.regexr.com/) for help with finding regular expression
- [R-help Archives](https://stat.ethz.ch/pipermail/r-help/) of the ETH Zürich's [Seminar For Statistics](https://stat.ethz.ch/)

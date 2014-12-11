Summarize Flattr Reports
---
R script to create summary CSV files and diagrams from Flattr's Monthly Revenue reports. [Example here](http://www.konscience.de/uber-uns/#flattr-auswertung).

Usage Instructions
---
1. Download and install both [RStudio](http://www.rstudio.com/products/rstudio/download/) and [R](http://cran.rstudio.com/).
1. Go to [your Flattr Transactions](https://flattr.com/dashboard/transactions).
  1. Open each "Monthly revenue"-report (or start with only a few).
  1. Click "Download as CSV".
  1. Save them to a folder of your choice.
1. Download [this script](https://github.com/KonScience/Summarize-Flattr-Reports/blob/master/summarize-flattr-reports.R) to the same or any other folder.
  1. Open the script (.r file) in RStudio.
  1. Run it with `alt+cmd+R` (Mac) or `ctrl+alt+R` (Win).
  1. Follow its progress in RStudios' `Console` and `Plot` tabs. This may take few seconds to several minutes, depending on your number of Flattr Revenue Reports, data points in them, and the speed of your computer. Example: 20 Reports with 200 data points at [2.3 GHz](http://www.everymac.com/systems/apple/macbook_pro/specs/macbook-pro-core-i5-2.3-13-early-2011-unibody-thunderbolt-specs.html): 10sec.
  1. Find the newly generated .csv files and .png diagrams in the same folder as the .csv files you downloaded from Flattr.
1. Please contribute ideas, criticism and code, by [opening an issue](https://github.com/KonScience/Summarize-Flattr-Reports/issues/new) or [forking](https://github.com/KonScience/Summarize-Flattr-Reports/fork) and sending a pull request. In particular, please let me know at which size of the dataset the diagrams become difficult to interpret.

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

Thanks and Greetings :-)
---
- Dr. Rick Scavetta of [Science Craft](http://www.science-craft.com/) and  [Konstanz Graduate School Chemical Biology](http://www.chembiol.uni-konstanz.de/) for the Data Analysis course
- [RegExr](http://www.regexr.com/) for help with finding regular expression
- [R-help Archives](https://stat.ethz.ch/pipermail/r-help/) of the ETH Zürich's [Seminar For Statistics](https://stat.ethz.ch/)

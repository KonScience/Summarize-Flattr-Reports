Summarize Flattr Reports
---

R script to create summary CSV file from [Flattr's individual Monthly Revenue reports](https://flattr.com/dashboard/transactions).



Usage Instructions
---

1. Open your ["Monthly Revenue" reports on Flattr](https://flattr.com/dashboard/transactions)
2. Click "Download as CSV" for all of them and save them to a folder of your choice.
2. Download [script](https://github.com/KonScience/Summarise-Flattr-Reports/blob/master/summarise-flattr-reports.R) to same or any other folder.
4. Download [R](http://www.r-project.org/) (directly for [Windows](http://cran.rstudio.com/bin/windows/base/), [Mac OS X](http://cran.rstudio.com/bin/macosx/) or [Linux](http://cran.rstudio.com/bin/linux/)) or [RStudio](http://www.rstudio.com/products/rstudio/download/) and install.
6. Run downloaded summarise-flattr-reports.R and either look at the "all_Flattrs"-dataframe in RStudio or the "flattr-revenue-summary.csv"-file.



To Do (Ideas and Contributions Welcome!)
---

- ~~sort data usefully~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/pull/1)
- simplify data input (~~better file/folder selection~~ [DONE](https://github.com/KonScience/Summarize-Flattr-Reports/commit/c4b8f15d4d0bdb8001b3a7255bb71077e76b8638), or download from flattr.com)
- draw more useful diagrams (coloration of datapoints per Flattr thing, etc.)



Thanks and Greetings :-)
---

- Dr. Rick Scavetta of [Science Craft](http://www.science-craft.com/) and  [Konstanz Graduate School Chemical Biology](http://www.chembiol.uni-konstanz.de/) for the Data Analysis course
- [RegExr](http://www.regexr.com/) for help with finding regular expression
- [R-help Archives](https://stat.ethz.ch/pipermail/r-help/) of the ETH Zürich's [Seminar For Statistics](https://stat.ethz.ch/)

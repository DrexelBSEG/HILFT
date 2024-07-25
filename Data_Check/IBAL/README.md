# Data Check

> The data provided in this folder is not the complete set. It is used as an example input. For the formal published data, please refer to: [https://doi.org/10.18434/mds2-3058](https://doi.org/10.18434/mds2-3058).

## Repository Structure
- `DataCheck.m`: Main script to perform data checking. It takes a file from the `\data` folder (by specifying the file name at the begining of the script), and returns the results to the `\report` folder. The algorithm's outputs may not strictly align with the pass/fail criteria detailed in the final report, as it was used for preliminary checks during the data verification process. The actual verification process followed the rules outlined in the final report.
- `\qcfunc`: Subfunctions used by the main script.
- `\data`: Folder for the raw data. Note that the script only works on the raw data.
- `\report`: Folder for storing data checking results.


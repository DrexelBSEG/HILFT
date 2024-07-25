# Data Check

> The data provided in this folder is not the complete set. It is used as an example input. For the formal published data, please refer to: [https://doi.org/10.18434/mds2-3058](https://doi.org/10.18434/mds2-3058).

## Repository Structure
- `ASHP_DataCheck.mlx`: Main script to perform data checking. It takes a file from the `\data` folder (by specifying the file name at the begining of the script), and returns the results to the `\report` folder. The overall checking result is either a Pass or a Fail. A Fail case shall be further examined to determine if it is acceptable or not.
- `\qcfunc`: Subfunctions used by the main script.
- `\unctrn`: Subfunctions used by the main script.
- `\data`: Folder for the raw data. Note that the script only works on the raw data.
- `\report`: Folder for storing data checking results.


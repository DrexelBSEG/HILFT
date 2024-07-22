# HILFT Software Testbed
> **Note**: This folder contains the simulation components required for HIL testing. The main script, `callSim.m`, handles the interaction between different simulation components. To perform a HIL test, the `callSim.m` function must be called on the hardware side, typically through LabVIEW. The `ExampleCall.m` file demonstrates how `callSim.m` is called. However, simply running the script will not produce any useful testing results.

## Prerequisite
To successfully run the simulation, the following software packages are needed:

**Matlab 2020a**
-   Simulink
-   Parallel Computing Toolbox
-   Database Toolbox
-   Database Toolbox Interface for MongoDB
-   Deep Learning Toolbox
-   Deep Learning Toolbox Converter for TensorFlow Models
-   Statistics and Machine Learning Toolbox
-   Optimization Toolbox

**MongoDB 4.0**
-   Download from: [MongoDB community version](https://www.mongodb.com/try/download/community)
-   Other versions may work, but they have not been verified.
-   Install with default settings.
-   After installation, create the `C:\data\db\` directory.

**Matlab MongoDB connection**
-   Create a database named `HILFT` in MongoDB.
-   If you encounter an issue with `conn = mongo(server,port,dbname)`, ensure that the server, port, and dbname match your MongoDB configuration. By default, these inputs should be: `server='localhost'`, `port=27017`, `dbname='[your database name]'`. The easiest way to find this information is to connect to the database using MongoDB Compass, where you can find the host information in the left panel.

**EnergyPlus 9.3**
-   Add the EnergyPlus directory to the system path.

## File Description
 -   `ExampleCall.m`: An example code that calls the simulation package during HIL testing. 
 -  `callSim.m`: The main function for all simulation-side activities. Refer to the code's note for details about the function's input and output. 
 - `DataDL.m`: The code pulls data from MongoDB, the EPlus folder, and the HardwareData folder, and generates a final `.mat` file. The file is constructed as `foldernam_MMDDYYYY_HHMMSS`.
 - `\CTRL`: The folder includes the code to determine the system control signal. 
 - `\DB`: The folder includes subfunctions for reading and writing data related to MongoDB.
 - `\HardwareData`: The folder is used to store hardware data.
 - `\OBM`: The folder includes code related to the occupant behavior model.
 - `\VB`: The folder includes the Simulink model for all simulation scenarios.
 - `settings.csv`: The settings file for the testing. This file is used to select the testing scenario, including the season, location, GEB case, control method, occupant type, and building code. Refer to the note in the file for details about the settings.  
	- Based on the `Location`, the corresponding Simulink file in the `\VB` folder will be used.
	- Based on the selected `SeasonType`, the simulation time in Simulink will be adjusted.
	- Based on the selected `GEB_case`, the system control signal (zone cooling/heating setpoint) will be determined. 
	- The `Control_method` is used to define whether to use rule-based control or model predictive control.
	- The `occ_dense` and `occ_energysaving` are used to set the occupant group, whether it is a dense group or an energy-saving group. Three optional occupant files are in the `\OBM` folder, named `Fixed_OccupantMatrix.mat`, `Fixed_OccupantMatrix_dense.mat`, and `Fixed_OccupantMatrix_NGRSave.mat`.
	- The `STD` is used to determine the building type, whether it is a typical building or a high-performance building. This is also related to the Simulink files used for simulation.
	- The `TES` is used to set whether the building has thermal energy storage using phase change material. 
	- Other settings include:
		 - `stepsize`: The simulation timestep. 
		 - `recv`: Whether in recovery mode, which is used for test recovery in case of unexpected interruption.
		 - `ts_recv`: The timestep that needs to be recovered.
		 - `coll_recv`: The MongoDB collection name used for recovery.


# BrainAGE as a metric of maturation in early adolescence

Model training/testing code, analyses, and visualizations for a project examining the relationships between BrainAGE and maturational metrics. 

This repository contains code for the training and testing of a novel BrainAGE adolescent BrainAGE model, as well as code for the analyses and visualizations found in Whitmore, Weston, & Mills (https://doi.org/10.1162/imag_a_00037)

If you're interested in using the model to make predictions on your own data, follow the instructions below:

1. Download the model file: UpdatedModels/fit_workflow_combat.rds for baseline model, or UpdatedModels/fit_workflow_combat_followup.rds for follow-up model.

3. Prepare your own data. To make predictions, you should have a file with a column for age, and then columns for the brain features listed in feature_list.txt. Make sure your column names match up with the feature list. If you need to convert the names of your data columns, there are a few examples contained in the files within this repository. For converting from ABCD output, use the code in DataSetup.Rmd [lines 73-287]. For converting from Freesurfer output, use FreeSurferSetupBrainAGE.Rmd as a template (in progress, may be a few remaining bugs).

4. Once you've confirmed your data is in the correct format, run ABCDModel.Rmd (for baseline) or ABCDModelModelTraining_Followup.Rmd (lines 221-304, for follow-up) to get new predictions. 

5. To perform bias correction, run lines 130-142 of ABCDModel.Rmd (baseline) and lines 253-288 of ABCDModelModelTraining_Followup.Rmd (follow-up).

If you want to train your own model, you can modify or use the code from UpdatedModels/ABCDModelTraining.Rmd (h/t to Vlad Drobinin for the original model training code (linked in /DevelopmentalBrainAGE), which has been updated to use workflows).

Finally, if you have any questions about the code or project, or encounter any bugs, please reach out to me at lwhitmor@uoregon.edu

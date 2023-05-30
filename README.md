# FYP

Model training/testing code, analyses, and visualizations for a project examining the relationships between BrainAGE and maturational metrics. 

This repository contains code for the training and testing of a novel BrainAGE adolescent BrainAGE model, as well as code for the analyses and visualizations found in Whitmore, Weston, & Mills (in prep). [preprint link]

If you're interested in using the model to make predictions on your own data, follow the instructions below:

1. Download the model file:

3. Prepare your own data. To make predictions, you should have a file with a column for age, and then columns for the brain features listed in feature_list.txt. Make sure your column names match up with the feature list. If you need to convert the names of your data columns, there are a few examples contained in the files within this repository. For converting from ABCD output, use the code in DataSetup.Rmd [lines 73-287]. For converting from Freesurfer output, use [code coming soon].

4. Once you've confirmed your data is in the correct format, run ABCDModel.Rmd to get new predictions. 

5. To perform bias correction, run lines 130-142 of ABCDModel.Rmd. 


If you want to train your own model, use the code from UpdatedModels/ABCDModelTraining.Rmd (h/t to Vlad Drobonin for the original model training code, which has been updated to use workflows)

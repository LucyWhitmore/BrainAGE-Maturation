library(dplyr)
library(parallel)
library(doParallel)
library(tidymodels)

#load data


load("/projects/dcnlab/shared/brainage/abcd_train_multiwave.Rds")

# Model prep: split, preprocessing, CV ------------------------------------

# Train / test split ------------------------------------------------------
set.seed(42)
df_split <- initial_split(
  abcd_train_multiwave, 
  prop = 0.80,
  # matching age distributions across train and test set
  strata = "interview_age"
)

df_train <- training(df_split)
df_validation <- testing(df_split)

# report n training, features, testing
#df_train_baseline %>% 
df_train%>%
  summarise(
    n_training = n(),
    p_features = ncol(df_train)
  ) %>%
  bind_cols(df_validation %>%
              summarise(n_testing = n()))

# Pre-processing setup ----------------------------------------------------

# define (what we want to do)
preprocess_recipe <- df_train %>%
  #preprocess_recipe_baseline <- train_test %>%
  # predict scan age by all brain features
  recipe(interview_age ~ .) %>%
  # remove near zero variance predictors
  step_nzv(all_predictors()) %>%
  prep() # where it all gets calculated

preprocess_recipe


# Apply pre-processing ----------------------------------------------------

# juice() will work with training data, `bake()` to apply this to our test data

# apply on train (gives processed value)
df_train_prep <- juice(preprocess_recipe)

# apply on validation
df_validation_prep <- preprocess_recipe_baseline %>% bake(df_validation)


# Cross-validation --------------------------------------------------------

# 10 fold cv repeated 10 times
set.seed(42)
train_cv <- df_train_prep %>%
  vfold_cv(
    v = 10, 
    repeats = 10, 
    strata = interview_age
  )


#Train and Fit Model (Baseline)

# Extreme gradient boosting
# Parallel processing -----------------------------------------------------

all_cores <- parallel::detectCores(logical = TRUE)
# for 8 core 16 thread machine, good performance running more than 
# physical but less than all logical
registerDoParallel(cores = all_cores - 6) 

# Model specification -----------------------------------------------------

boost_mod <- boost_tree(
  mode = "regression", 
  trees = 1500, 
  tree_depth = tune(), min_n = tune(), loss_reduction = tune(),
  # randomness
  sample_size = tune(), mtry = tune(), 
  # step size
  learn_rate = tune()
) %>%
  set_engine("xgboost", 
             objective = "reg:squarederror")

# Model parameters --------------------------------------------------------

set.seed(42)

# filled 6 dimensional tuning space
xgboost_grid <- grid_latin_hypercube(
  min_n(), tree_depth(), loss_reduction(),
  sample_size = sample_prop(),
  # has unknown, finalize with data to find max
  finalize(mtry(), df_train_prep),
  learn_rate(),
  size = 500 
)

# Model tuning -----------------------------------------------------------

#tictoc::tic()

set.seed(42)
xgb_tuned_results <- tune_grid(
  boost_mod,
  interview_age ~ .,
  resamples = train_cv,
  grid = xgboost_grid,
  metrics = metric_set(mae, rmse, rsq),
  control = control_grid(verbose = FALSE,
                         save_pred = TRUE)
)

#tictoc::toc()
#beepr::beep(2)

# Pick best model ---------------------------------------------------------

xgb_tuned_results %>%
  # want to minimize MAE
  show_best("mae") 

# select parsimonious params within one SE of best model
best_xgb_params <- xgb_tuned_results %>%
  select_by_one_std_err(metric = "mae", maximize = FALSE, tree_depth) 


# Fit and save best model -------------------------------------------------

xgb_final_mod_multiwave <- boost_mod %>%
  finalize_model(best_xgb_params) %>%
  fit(interview_age ~ .,
      data = df_train_prep)


# save mod
saveRDS(xgb_final_mod_multiwave, file = here::here("xgboost_abcd_multiwave_brain_age_mod.rds")
)

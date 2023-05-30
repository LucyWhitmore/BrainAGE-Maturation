
library(dplyr)
library(parallel)
library(doParallel)
library(tidymodels)
library(xgboost)

#load data


load("/projects/dcnlab/shared/brainage/sample_train_diff.Rda")

# Model prep: split, preprocessing, CV ------------------------------------

# Train / test split ------------------------------------------------------
set.seed(42)
df_split_diff <- initial_split(
  sample_train_diff, 
  prop = 0.80,
  # matching age distributions across train and test set
  strata = "age_midpoint"
)

df_train_diff <- training(df_split_diff)
df_validation_diff <- testing(df_split_diff)

# report n training, features, testing
#df_train_baseline %>% 
df_train_diff%>%
  summarise(
    n_training = n(),
    p_features = ncol(df_train_diff)
  ) %>%
  bind_cols(df_validation_diff %>%
              summarise(n_testing = n()))

# Pre-processing setup ----------------------------------------------------

# define (what we want to do)
preprocess_recipe_diff <- df_train_diff %>%
#preprocess_recipe_baseline <- train_test %>%
  # predict scan age by all brain features
  recipe(age_midpoint ~ .) %>%
  # remove near zero variance predictors
  step_nzv(all_predictors()) %>%
  prep() # where it all gets calculated

preprocess_recipe_diff


# Apply pre-processing ----------------------------------------------------

# juice() will work with training data, `bake()` to apply this to our test data

# apply on train (gives processed value)
df_train_prep_diff <- juice(preprocess_recipe_diff)

# apply on validation
df_validation_prep_diff <- preprocess_recipe_diff %>% bake(df_validation_diff)
#df_validation_prep_baseline <- preprocess_recipe_baseline %>% bake(validation_test)


# Cross-validation --------------------------------------------------------

# 10 fold cv repeated 10 times
set.seed(42)
train_cv_diff <- df_train_prep_diff %>%
  vfold_cv(
    v = 10, 
    repeats = 10, 
    strata = age_midpoint
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
  trees = 100, #changed from 1500
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
  finalize(mtry(), df_train_prep_diff),
  learn_rate(),
  size = 500 
)

# Model tuning -----------------------------------------------------------

#tictoc::tic()

set.seed(42)
xgb_tuned_results <- tune_grid(
  boost_mod,
  age_midpoint ~ .,
  resamples = train_cv_diff,
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

xgb_final_mod <- boost_mod %>%
  finalize_model(best_xgb_params) %>%
  fit(age_midpoint ~ .,
      data = df_train_prep_diff)

#update version
xgb_final_mod_updated <- boost_mod %>%
  finalize_model(best_xgb_params) %>%
  fit(age_midpoint ~ .,
      data = df_train_prep_diff)


class(xgb_final_mod)
class(xgb_final_mod_updated)


# save mod
saveRDS(xgb_final_mod, file = here::here("xgboost_abcd_diff_brain_age_mod.rds"))
saveRDS(xgb_final_mod, file = here::here("xgboost_abcd_diff_brain_age_mod_updated.rds"))


mod_bundle <- bundle(xgb_final_mod)
saveRDS(mod_bundle, file = here::here("abcd_diff_mod_bundle.rds"))


xgb.save.raw(xgb_final_mod, 'abcd_diff.model')
xgb.save(xgb_final_mod, 'abcd_diff.model')
xgb.save(xgb_final_mod, 'abcd_diff_model.json')


#savexgb - save rds no longer works in new versions of xgboost (won't predict)

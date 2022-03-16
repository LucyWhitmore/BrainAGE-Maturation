# Extreme gradient boosting
# Parallel processing -----------------------------------------------------

library(doParallel)
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

tictoc::tic()

set.seed(42)
xgb_tuned_results <- tune_grid(
  boost_mod,
  scan_age ~ .,
  resamples = train_cv,
  grid = xgboost_grid,
  metrics = metric_set(mae, rmse, rsq),
  control = control_grid(verbose = FALSE,
                         save_pred = TRUE)
)

tictoc::toc()
beepr::beep(2)

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
  fit(scan_age ~ .,
      data = df_train_prep)


# save mod
saveRDS(xgb_final_mod, file = here::here(
  "model", "xgboost_9to19_brain_age_mod.rds")
  )
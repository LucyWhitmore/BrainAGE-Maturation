# Model prep: split, preprocessing, CV ------------------------------------

# Train / test split ------------------------------------------------------

set.seed(42)
df_split <- initial_split(
  df_select,
  prop = 0.80,
  # matching age distributions across train and test set
  strata = "scan_age"
)

df_train <- training(df_split)
df_validation <- testing(df_split)

# report n training, features, testing
df_train %>%
  summarise(
    n_training = n(),
    p_features = ncol(df_train)
  ) %>%
  bind_cols(df_validation %>%
              summarise(n_testing = n()))

# Pre-processing setup ----------------------------------------------------

# define (what we want to do)
preprocess_recipe <- df_train %>%
  # predict scan age by all brain features
  recipe(scan_age ~ .) %>%
  # remove near zero variance predictors
  step_nzv(all_predictors()) %>%
  prep() # where it all gets calculated

preprocess_recipe


# Apply pre-processing ----------------------------------------------------

# juice() will work with training data, `bake()` to apply this to our test data

# apply on train (gives processed value)
df_train_prep <- juice(preprocess_recipe)

# apply on validation
df_validation_prep <- preprocess_recipe %>% bake(df_validation)

# pre process on all of forbow
frb_prep <- preprocess_recipe %>% bake(frb_select)


# Cross-validation --------------------------------------------------------

# 10 fold cv repeated 10 times
set.seed(42)
train_cv <- df_train_prep %>%
  vfold_cv(
    v = 10, 
    repeats = 10, 
    strata = scan_age
  )
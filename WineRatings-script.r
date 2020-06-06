#############################################################################################
# Install and/or load necessary packages
#############################################################################################

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(Rborist)) install.packages("Rborist", repos = "http://cran.us.r-project.org")


#############################################################################################
# Download data set from url and read csv file into environment
#############################################################################################

url <- "https://www.dropbox.com/s/wug790n9fqrj7uz/winemag-data-130k-v2.csv?dl=1"

# Check if file is already saved, otherwise download it from url
if(!file.exists("./wineratings/winemag-data-130k-v2.csv")){
  download.file(url, "./wineratings/winemag-data-130k-v2.csv")
}

# Load data set csv file
dataset <- read.csv("./wineratings/winemag-data-130k-v2.csv",  encoding = "UTF-8")


#############################################################################################
# Data cleaning and processing of data set
#############################################################################################

# Extract vintage year information from wine titles and save as vintage variable
dataset <- dataset %>% mutate(vintage = as.numeric(substr(title, str_length(winery)+2,
                                                          str_length(winery)+5)))


# Filter out NA or blank entries for the relevant variables in our data set
dataset <- dataset %>% filter(!is.na(price) & price != "" &
                                !is.na(country) & country != "" &
                                !is.na(province) & province != "" &
                                !is.na(variety) & variety != "" &
                                !is.na(vintage) & vintage != "")

# We filter the data set to only include the columns that will be relevant for our study 
dataset <- dataset %>% select(points, description, price, province, variety, vintage)


#############################################################################################
# Construct training and test sets from our data set
#############################################################################################

# Set sample seed to 1 for replicability of results
set.seed(1, sample.kind="Rounding")

 
# We sample 10,000 entries from the data set to have a more manageable size on which to run our algorithms
  dataset <- dataset %>% sample_n(10000) %>%
# Then we add a category variable with the stratified points scores
  mutate(category = as.factor(case_when(points > 97 ~ "A",
                                        points > 93 ~ "B",   
                                        points > 89 ~ "C",
                                        points > 86 ~ "D",
                                        points > 82 ~ "E",
                                        points >= 80 ~ "F")))

# Set sample seed to 1 for replicability of results
set.seed(1, sample.kind="Rounding")

# We create a test index using 20% of the entries in the dataset
test_index <- createDataPartition(y = dataset$points, times = 1, p = 0.2, list = FALSE)

# We then create the 80% training and 20% test sets using the test index
train_set <- dataset[-test_index,]
test_set <- dataset[test_index,]

# Make sure that provinces and varieties in the test set are also in the training set so that
# our models do not encounter any unknown cases when making predictions
test_set <- test_set %>% 
  semi_join(train_set, by = "province") %>%
  semi_join(train_set, by = "variety")

# Remove unused factor levels for the variety and province variables in the training and test sets
train_set <- train_set %>% mutate(variety = droplevels(variety),
                                  province = droplevels(province))
test_set <- test_set %>% mutate(variety = droplevels(variety),
                                province = droplevels(province))

# Match the factor levels in the test set to those in the training set to prepare for use in our models
levels(test_set$variety) <- levels(train_set$variety)
levels(test_set$province) <- levels(train_set$province)

# Removing the dataset and test_index objects to clean up since they are no longer needed
rm(dataset, test_index)

# Remove unrequired points and description variables from training and testing sets prior to model training
train_set <- train_set %>% select(-description, -points)
test_set <- test_set %>% select(-description, -points)

#############################################################################################
# Training of machine learning algorithm on training set with cross validation
#############################################################################################

# Set to 3-fold cross validation for training our model in order to save on computing time
control <- trainControl(method="cv", number = 3)

# Set our tuning parameters to test on the random forest model, the minimum node size and number of predictors used
grid <- expand.grid(minNode = c(1,5, 10) , predFixed = seq(20,80,10))

# Train random forest model on train_set with 50 trees sampling 500 rows each
train_rf <- train(category ~ .,
                  method = "Rborist",
                  data = train_set,
                  nTree = 50,
                  tuneGrid = grid,
                  trControl = control,
                  nSamp = 500)

# Print our optimal parameters from the cross validation
train_rf$bestTune


#############################################################################################
# Training of final random forest model on training set with optimal parameters
#############################################################################################

# Create a matrix of predictors for the training set which creates dummy variables that are either 1 or 0
# for each factor variable level since this is required for the Rborist function that we will use
dummyvars <- dummyVars( ~ price + vintage + variety + province, data = train_set)
train_dummyvars <- predict(dummyvars, newdata = train_set)

# Set our training set outcomes in a separate vector for use with the Rborist function
y_train <- train_set$category

# Train final random forest model using train_set dummy variable matrix and outcomes with 500 trees
final_model <- Rborist(x = train_dummyvars,
                       y = y_train,
                       nTree = 500,
                       predFixed = train_rf$bestTune$predFixed, # Optimal paramenter from earlier training
                       minNode = train_rf$bestTune$minNode)     # Optimal paramenter from earlier training


#############################################################################################
# Test final model on test set
#############################################################################################

# Create a matrix of predictors for the test set with dummy variables for factor levels
dummyvars <- dummyVars( ~ price + vintage + variety + province, data = test_set)
test_dummyvars <- predict(dummyvars, newdata = test_set)

# Create our model predictions for the test set using the final model and test set matrix of predictors
y_hat <- as.factor(predict(final_model, test_dummyvars)$yPred)

# Create confusion matrix and print
cm <- confusionMatrix(y_hat, test_set$category)
cm

# Print final model accuracy from confusion matrix
cm$overall["Accuracy"]











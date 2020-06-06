# WineRatings
In this project, we will study a data set of wine ratings available on Kaggle (https://www.kaggle.com/zynicide/wine-reviews/data). The data set comprises information on wine reviews scraped from the Wine Enthusiast Magazine website (https://www.winemag.com/ratings/) on November 22nd, 2017.

Our data set contains nearly 130,000 reviews written by wine critics for the magazine with information on wine grape variety, price, place of origin, and several others. The full text of the review is included for each entry, as well as a points score between 80-100, which can be categorized in the following six categories (see https://www.winemag.com/wine-vintage-chart/):

Score  | Category
------ | ----------
98-100 | Classic 
94-97  | Superb
90-93  | Excellent
87-89  | Very Good
83-86  | Good
80-82  | Acceptable

Wines scoring below 80 are not reviewed or recommended by the magazine.

We will look to build a machine learning algorithm which will predict one of the six score categories for wines with unknown titles or wineries by utilizing other available variables in the data set. We will first explore the data set in some detail to undertake necessary data cleaning and to determine which variables are useable based on the available data.

Then we will construct training and testing subsets from the full data set with points scores stratified by category, and perform some data visualization to evaluate each variable's usefulness in predicting wine score categories.

We then train classification tree, random forest, multinomial logistic regression, QDA, and kNN models on the training set and we will assess them based on their accuracy rate in determining correct points categories.

Finally, once we determine the model with the highest accuracy, we use it to make predictions our testing set, review its accuracy performance, and provide suggestions for improvements or next steps for further study.

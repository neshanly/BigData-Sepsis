library(xgboost)
library(caret)
library(dplyr)

set.seed(1)

a <- read.csv("D:/Nesha/ehr_sepsis_dummy.csv", sep = ";", stringsAsFactors = FALSE)

a <- a[, c("age", "sex", "temperature", "heart_rate", "respiratory_rate",
           "systolic_bp", "diastolic_bp", "wbc_count", "lactate",
           "creatinine", "oxygen_saturation", "comorbidity_diabetes",
           "comorbidity_ckd", "sepsis_outcome")]

a <- a[!is.na(a$sepsis_outcome), ]

for (i in names(a)) {
  if (i != "sepsis_outcome") {
    if (is.numeric(a[[i]]) || is.integer(a[[i]])) {
      a[[i]][is.na(a[[i]])] <- median(a[[i]], na.rm = TRUE)
    } else {
      a[[i]][is.na(a[[i]])] <- names(sort(table(a[[i]]), decreasing = TRUE))[1]
      a[[i]] <- as.factor(a[[i]])
    }
  }
}

a$sepsis_outcome <- as.numeric(a$sepsis_outcome)
b <- model.matrix(sepsis_outcome ~ . - 1, a)
c <- a$sepsis_outcome
d <- createDataPartition(c, p = .8, list = FALSE)
e <- xgb.DMatrix(b[d, ], label = c[d])
f <- xgb.DMatrix(b[-d, ], label = c[-d])
g <- xgb.train(list(objective = "binary:logistic", eval_metric = "logloss",
                    max_depth = 3, eta = .1), e, nrounds = 50, verbose = 0)
h <- predict(g, f)
i <- ifelse(h >= .5, 1, 0)
j <- data.frame(c[-d], h, i)
print(head(j))
print(confusionMatrix(as.factor(i), as.factor(c[-d]), positive = "1"))
print(xgb.importance(feature_names = colnames(b), model = g))


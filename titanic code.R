library(caret)
library(pROC)
library(rpart)
library(stringr)
dTest <- read.csv("Downloads/titanic/test.csv")
dTrain <- read.csv("Downloads/titanic/train.csv")

total = rbind(select(dTrain,-Survived),dTest)

summary(total)

total$Sex = ifelse(total$Sex=='male',1,0)
result = c()
for (char in total$Name){
result = c(result,str_extract(char,'\\s[A-Z][a-z]+[.]+'))
}
result = str_remove(result,'[[:space:]]') %>% str_remove('[.]')
total = cbind(total,Title = result)
summary(total)
total$Title[total$Title %in% c('Lady', 'Countess', 'Mlle', 'Mme', 'Ms')] = 'Miss'
total$Title[total$Title %in% 
 c('Capt', 'Don', 'Major', 'Sir', 'Col', 'Jonkheer', 'Rev', 'Dr', 'Master')] = 'Mr'
total$Title[total$Title == 'Dona'] = 'Mrs'
total$Title = factor(total$Title)
total$Embarked[which(total$Embarked == '')] = 'S'
total$Embarked = factor(total$Embarked)
total$Fare[is.na(total$Fare)] = median(total$Fare,na.rm = T)
total$FamSize = total$SibSp + total$Parch + 1
predicted_age = rpart(Age ~ Pclass + Sex + SibSp + Parch + Fare + Embarked + Title + FamSize,
                    data=total[!is.na(total$Age),], method="anova")
total$Age[is.na(total$Age)] = predict(predicted_age,total[is.na(total$Age),])
total$Age = ifelse(total$Age < 13,'0',ifelse(total$Age <19,1,ifelse(total$Age<60,2,3)))
#0: Child (0-12 years), 1: Adolescence (13-18 years), 2: Adult (19-59 years) and 3: Senior Adult (60 years and above)

dTrain_new = cbind(total[dTrain$PassengerId,],Survived = dTrain$Survived)
dTrain_new$Survived = as.factor(dTrain_new$Survived)
dTest_new = total[dTest$PassengerId,]
dTest_new$Survived = NA


ctree = train(Survived ~ Pclass + Sex + Age + FamSize ,data = dTrain_new,method = 'ctree')
predictLabel_ctree = predict(ctree,dTest_new)

PassengerId = dTest_new$PassengerId
output = as.data.frame(PassengerId)
output$Survived = predictLabel_ctree
output
write.csv(output,'kaggle_submission.csv')

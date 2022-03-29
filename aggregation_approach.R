set.seed(2021)
library(tidyverse)
library(e1071) 
library(caTools) 
library(caret) 
library(rpart.plot)
library(rpart)
library(stringr)

setwd("ba/cup")

co = read_csv("companies.csv")
pa = read_csv("payments.csv")
ph = read_csv("physicians.csv")


data = as.data.frame(ph)


# numeric 
require(dplyr)
pa <- pa %>%
  mutate(Ownership_Indicator = ifelse(Ownership_Indicator == "No",0,1))


#merge companies and payments
df <- merge(pa, co, by.x = 'Company_ID', by.y = 'Company_ID')



# create Physician_ID - Ownership table
ownership <- merge(df, ph, by.x = 'Physician_ID', by.y = 'id')
ownership <- ownership %>% select(Physician_ID, Ownership_Indicator)
ownership <- aggregate(ownership,
                       by = list(ownership$Physician_ID),
                       FUN = max)
  #drop group column
ownership <- ownership[-1]

#merge ownership indicator per physician
data <- merge(data, ownership, by.x = 'id', by.y = 'Physician_ID')

#rename ownership_indicator
data <- data %>%
  rename(prediction = Ownership_Indicator)

# drop first_name, middle_name, last_name, name_suffix, zipcode, province
data =  data %>% select(-First_Name, -Middle_Name, -Last_Name, -Name_Suffix, -Zipcode, -Province)

# experimental: drop further columns
df =  df %>% select(-Date, -Contextual_Information, -Product_Category_2, -Product_Category_3)

#rename columns
df <- df %>%
  rename(
    State_Co = State,
    Country_Co = Country
  )

#separate columns by aggregation method

#aggregation by most frequent value
agg1 <- df %>% select(Physician_ID,
                      Form_of_Payment_or_Transfer_of_Value,
                      Nature_of_Payment_or_Transfer_of_Value,
#                      City_of_Travel,
                      State_of_Travel,
#                      Country_of_Travel,
                      Third_Party_Recipient,
                      Charity,
                      Third_Party_Covered,
                      Related_Product_Indicator,
                      Product_Code_1,
                      Product_Code_2,
#                      Product_Code_3,
                      Product_Type_1,
#                      Product_Type_2,
#                      Product_Type_3,
#                      Product_Name_1,
#                      Product_Name_2,
#                      Product_Name_3,
                      Company_ID,
                      Product_Category_1,
                      State_Co,
                      Country_Co
                      )


#aggregate by mode

  #define mode function
Mode <- function(x) {
  out <- unique(x[!is.na(x)]) #ignore NAs
  out[which.max(tabulate(match(x, out)))]
}


for (i in 2:ncol(agg1)){
  aggregation <- aggregate(agg1[,i] ~ agg1$Physician_ID, agg1, Mode, na.action = na.pass)
  data <- merge(data, aggregation, by.x = 'id', by.y = 'agg1$Physician_ID')
  
  #rename new column
  name <- paste("Top_", names(agg1[i]), sep = "")
  colnames(data)[ncol(data)] <- name
  #glimpse(data)
}



#aggregation by sum
agg2 <- df %>% select(Physician_ID,
                      Number_of_Payments,
                      Total_Amount_of_Payment_USDollars
)

for (i in 2:ncol(agg2)){
  aggregation <- aggregate(agg2[,i] ~ agg2$Physician_ID, agg2, FUN = sum, na.action = na.pass)
  data <- merge(data, aggregation, by.x = 'id', by.y = 'agg2$Physician_ID')
  
  #rename new column
  name <- paste0("Sum_", names(agg2[i]))
  colnames(data)[ncol(data)] <- name
  #glimpse(data)
}

#aggregation by number of observations (i.e. transactions)
aggregation <- df %>% count(Physician_ID)
data <- merge(data, aggregation, by.x = 'id', by.y = 'Physician_ID')

  #rename new column
colnames(data)[ncol(data)] <- "Nr_of_Transaction"


#determine travel indicator i.e. if company paid for trip of physician
data$Travel_Indicator = ifelse(!is.na(data$`Top_State_of_Travel`), 1, 0)


#same state indicator company and physician
data$Same_State_Indicator = ifelse(data$License_State_1 == data$State, 1, 0)


#"Allopathic & Osteopathic Physicians|Psychiatry & Neurology|Neurology"
#split primary specialty into several columns
#data <- separate(data = data, col = Primary_Specialty, into = c("Specialty_1", "Specialty_2"), sep = "\\|")


#create Physician_Type columns
data$Neurology_Indicator = ifelse(grepl("Neuro", data$Primary_Specialty, fixed = TRUE), 1, 0)
data$Pediatrician_Indicator = ifelse((grepl("Child", data$Primary_Specialty, fixed = TRUE)|
                                        grepl("Pediatr", data$Primary_Specialty, fixed = TRUE)|
                                        grepl("Family", data$Primary_Specialty, fixed = TRUE)), 1, 0)
data$Psychology_Indicator = ifelse((grepl("Psych", data$Primary_Specialty, fixed = TRUE)|
                                        grepl("psych", data$Primary_Specialty, fixed = TRUE)), 1, 0)
data$Urology_Indicator = ifelse((grepl("Urology", data$Primary_Specialty, fixed = TRUE)), 1, 0)
data$Ophtalmology_Indicator = ifelse((grepl("Ophtalmo", data$Primary_Specialty, fixed = TRUE)), 1, 0)
data$Dentology_Indicator = ifelse((grepl("Dentist", data$Primary_Specialty, fixed = TRUE)), 1, 0)
data$Internal_Medicine_Indicator = ifelse((grepl("Internal Medicine", data$Primary_Specialty, fixed = TRUE)), 1, 0)
data$Orthopaedic_Indicator = ifelse((grepl("Orthopaedic", data$Primary_Specialty, fixed = TRUE)), 1, 0)

#aggregate number of specialties per physician
data$Nr_of_Specialties = str_count(data$Primary_Specialty, "\\|")

data_save <- data

data <- data_save

#convert to numerical
for (i in 2:ncol(data)){
  data[,i] = as.numeric(as.factor(data[,i]))
}

#fix prediction column (0 or 1)
data$prediction <- data$prediction - 1


#clean data
  #for the moment just put mode for all NAs
data %>%
  summarise_all(funs(sum(is.na(.))))
  # use mode for NAs
data <- data %>% mutate_all(~ifelse(is.na(.), Mode(.), .))



#experiment with columns, could drop some at this point
#data <- data %>% select(id,
#                        set,
#                        prediction,
#                        Neurology_Indicator,
#                        Psychology_Indicator,
#                        Pediatrician_Indicator,
#                        Urology_Indicator,
#                        Dentology_Indicator,
#                        Orthopaedic_Indicator,
#                        Ophtalmology_Indicator,
#                        Internal_Medicine_Indicator,
#                        Sum_Number_of_Payments,
#                        Sum_Total_Amount_of_Payment_USDollars,
#                        Nr_of_Transaction,
#                        Nr_of_Specialties
#                        )



#convert to categorical
data <- data %>%
  mutate(Sum_Number_of_Payments = case_when(
    Sum_Number_of_Payments <= 500 ~ "<=500",
    Sum_Number_of_Payments > 500 & Sum_Number_of_Payments <= 1000 ~ "500-1000",
    Sum_Number_of_Payments > 1000 & Sum_Number_of_Payments <= 1500 ~ "1000-1500",
    Sum_Number_of_Payments > 1500 & Sum_Number_of_Payments <= 2000 ~ "1500-2000",
    Sum_Number_of_Payments > 2000 & Sum_Number_of_Payments <= 2500 ~ "2000-2500",
    Sum_Number_of_Payments > 2500 & Sum_Number_of_Payments <= 3000 ~ "2500-3000",
    Sum_Number_of_Payments > 3000 & Sum_Number_of_Payments <= 3500 ~ "3000-3500",
    Sum_Number_of_Payments > 3500 & Sum_Number_of_Payments <= 4000 ~ "3500-4000",
    Sum_Number_of_Payments > 4000 & Sum_Number_of_Payments <= 4500 ~ "4000-4500",
    Sum_Number_of_Payments > 4500 & Sum_Number_of_Payments <= 5000 ~ "4500-5000",
    Sum_Number_of_Payments > 5000 & Sum_Number_of_Payments <= 5500 ~ "5000-5500",
    Sum_Number_of_Payments > 5500 & Sum_Number_of_Payments <= 6000 ~ "5500-6000",
    Sum_Number_of_Payments > 6000 & Sum_Number_of_Payments <= 6500 ~ "6000-6500",
    Sum_Number_of_Payments > 6500 & Sum_Number_of_Payments <= 7000 ~ "6500-7000",
    Sum_Number_of_Payments > 7000 & Sum_Number_of_Payments <= 7500 ~ "7000-7500",
    Sum_Number_of_Payments > 7500 & Sum_Number_of_Payments <= 8000 ~ "7500-8000",
    Sum_Number_of_Payments > 8000 & Sum_Number_of_Payments <= 8500 ~ "8000-8500",
    Sum_Number_of_Payments > 8500 ~ "8500+",
    TRUE ~ "NA"
  ))


data <- data %>%
  mutate(Nr_of_Transaction = case_when(
    Nr_of_Transaction <= 500 ~ "<=500",
    Nr_of_Transaction > 500 & Nr_of_Transaction <= 1000 ~ "500-1000",
    Nr_of_Transaction > 1000 & Nr_of_Transaction <= 1500 ~ "1000-1500",
    Nr_of_Transaction > 1500 & Nr_of_Transaction <= 2000 ~ "1500-2000",
    Nr_of_Transaction > 2000 & Nr_of_Transaction <= 2500 ~ "2000-2500",
    Nr_of_Transaction > 2500 & Nr_of_Transaction <= 3000 ~ "2500-3000",
    Nr_of_Transaction > 3000 & Nr_of_Transaction <= 3500 ~ "3000-3500",
    Nr_of_Transaction > 3500 & Nr_of_Transaction <= 4000 ~ "3500-4000",
    Nr_of_Transaction > 4000 & Nr_of_Transaction <= 4500 ~ "4000-4500",
    Nr_of_Transaction > 4500 & Nr_of_Transaction <= 5000 ~ "4500-5000",
    Nr_of_Transaction > 5000 & Nr_of_Transaction <= 5500 ~ "5000-5500",
    Nr_of_Transaction > 5500 & Nr_of_Transaction <= 6000 ~ "5500-6000",
    Nr_of_Transaction > 6000 & Nr_of_Transaction <= 6500 ~ "6000-6500",
    Nr_of_Transaction > 6500 & Nr_of_Transaction <= 7000 ~ "6500-7000",
    Nr_of_Transaction > 7000 & Nr_of_Transaction <= 7500 ~ "7000-7500",
    Nr_of_Transaction > 7500 & Nr_of_Transaction <= 8000 ~ "7500-8000",
    Nr_of_Transaction > 8000 & Nr_of_Transaction <= 8500 ~ "8000-8500",
    Nr_of_Transaction > 8500 ~ "8500+",
    TRUE ~ "NA"
  ))

data <- data %>%
  mutate(Sum_Total_Amount_of_Payment_USDollars = case_when(
    Sum_Total_Amount_of_Payment_USDollars <= 500 ~ "<=500",
    Sum_Total_Amount_of_Payment_USDollars > 500 & Sum_Total_Amount_of_Payment_USDollars <= 1000 ~ "500-1000",
    Sum_Total_Amount_of_Payment_USDollars > 1000 & Sum_Total_Amount_of_Payment_USDollars <= 1500 ~ "1000-1500",
    Sum_Total_Amount_of_Payment_USDollars > 1500 & Sum_Total_Amount_of_Payment_USDollars <= 2000 ~ "1500-2000",
    Sum_Total_Amount_of_Payment_USDollars > 2000 & Sum_Total_Amount_of_Payment_USDollars <= 2500 ~ "2000-2500",
    Sum_Total_Amount_of_Payment_USDollars > 2500 & Sum_Total_Amount_of_Payment_USDollars <= 3000 ~ "2500-3000",
    Sum_Total_Amount_of_Payment_USDollars > 3000 & Sum_Total_Amount_of_Payment_USDollars <= 3500 ~ "3000-3500",
    Sum_Total_Amount_of_Payment_USDollars > 3500 & Sum_Total_Amount_of_Payment_USDollars <= 4000 ~ "3500-4000",
    Sum_Total_Amount_of_Payment_USDollars > 4000 & Sum_Total_Amount_of_Payment_USDollars <= 4500 ~ "4000-4500",
    Sum_Total_Amount_of_Payment_USDollars > 4500 & Sum_Total_Amount_of_Payment_USDollars <= 5000 ~ "4500-5000",
    Sum_Total_Amount_of_Payment_USDollars > 5000 & Sum_Total_Amount_of_Payment_USDollars <= 5500 ~ "5000-5500",
    Sum_Total_Amount_of_Payment_USDollars > 5500 & Sum_Total_Amount_of_Payment_USDollars <= 6000 ~ "5500-6000",
    Sum_Total_Amount_of_Payment_USDollars > 6000 & Sum_Total_Amount_of_Payment_USDollars <= 6500 ~ "6000-6500",
    Sum_Total_Amount_of_Payment_USDollars > 6500 & Sum_Total_Amount_of_Payment_USDollars <= 7000 ~ "6500-7000",
    Sum_Total_Amount_of_Payment_USDollars > 7000 & Sum_Total_Amount_of_Payment_USDollars <= 7500 ~ "7000-7500",
    Sum_Total_Amount_of_Payment_USDollars > 7500 & Sum_Total_Amount_of_Payment_USDollars <= 8000 ~ "7500-8000",
    Sum_Total_Amount_of_Payment_USDollars > 8000 & Sum_Total_Amount_of_Payment_USDollars <= 8500 ~ "8000-8500",
    Sum_Total_Amount_of_Payment_USDollars > 8500 ~ "8500+",
    TRUE ~ "NA"
  ))

data <- data %>%
  mutate(Nr_of_Specialties = case_when(
    Nr_of_Specialties <= 1 ~ "=1",
    Nr_of_Specialties > 1 ~ ">1",
    TRUE ~ "NA"
  ))

data <- data %>%
  mutate(Neurology_Indicator = case_when(
    Neurology_Indicator == 1 ~ "=1",
    Neurology_Indicator == 2 ~ "=2",
    TRUE ~ "NA"
  ))

data <- data %>%
  mutate(Internal_Medicine_Indicator = case_when(
    Internal_Medicine_Indicator == 1 ~ "=1",
    Internal_Medicine_Indicator == 2 ~ "=2",
    TRUE ~ "NA"
  ))

data_save2 <- data

data <- data_save2



data <- data %>% select(id,
                        set,
                        prediction,
                        Nr_of_Specialties,
                        Nr_of_Transaction,
                        Sum_Number_of_Payments,
                        Sum_Total_Amount_of_Payment_USDollars,
                        Primary_Specialty,
                        Top_Company_ID
#                        Neurology_Indicator
                        )



for(i in 2:ncol(data)){
  data[,i] <- as.factor(data[,i])
}



# data set separation
train_data = data[data$set==2,]
test_data = data[data$set==1,]

# Splitting data into train and test data 
set.seed(2021)
split <- sample.split(train_data, SplitRatio = 0.8)

train_cl <- subset(train_data, split == "TRUE")
test_cl <- subset(train_data, split == "FALSE")



  
#stratify
#manually
owners <- filter(train_cl, train_cl$prediction == 1)
not_owners <- filter(train_cl, train_cl$prediction == 0)

owner_percentage <- 0.35

Nr_owners <- owner_percentage*nrow(train_cl)
Nr_not_owners <- (1-owner_percentage) * nrow(train_cl)

owners <- as_data_frame(sample(owners$id, size = Nr_owners, replace = TRUE))
not_owners <- as_data_frame(sample(not_owners$id, size = Nr_not_owners, replace = FALSE))

train1 <- merge(train_cl, owners, by.x = 'id', by.y = "value")
train2 <- merge(train_cl, not_owners, by.x = 'id', by.y = "value")
train_cl <- rbind(train1, train2)


train_cl = train_cl %>% select(-set)
test_cl = test_cl %>% select(-set)

# Feature Scaling 
#train_scale <- scale(train_cl) 
#test_scale <- scale(test_cl) 



#Naive bayes
classifier_cl <- naiveBayes(as.factor(prediction) ~ .-id, data = train_cl, laplace = 1) 
classifier_cl 

#Naive bayes exercise approach
#for (i in 2:ncol(train_cl)) {
#  train_subdata <- train_cl %>% select("prediction", i)
#  nb2 <- naiveBayes(as.factor(prediction) ~ ., data=train_subdata, laplace=1)
#  rules <- predict(nb2, train_subdata, type="class")
#  errorRate = nrow(train_subdata %>% filter(loan!=rules))/nrow(train_subdata)
#  table_1rule[nrow(table_1rule) + 1,] <- list(colnames(train[,i]), errorRate)
#  rm(errorRate, i, rules, train_subdata, nb2)
#}



# Predicting on test data' 
y_pred <- predict(classifier_cl, newdata = data.frame(test_cl))

# Confusion Matrix 
cm <- table(test_cl$prediction, y_pred) 
cm 

# Model Evauation 
confusionMatrix(cm) 



#create submission
#prediction with test set of physicians
submission = as.data.frame(test_data$id)
#prediction here final submission prediction
submission$prediction = 0
colnames(submission)[1] <- "id"

#predict for test data with test_df
#test_df_scale <- scale(test_data)
y_pred2 <-predict(classifier_cl, test_data, type = 'class')


test_data$prediction2 = y_pred2

yes = test_data[test_data$prediction2==1,]
for(i in 1:nrow(yes)) {
  row <- yes[i,]
  submission[submission$id==row$id,]["prediction"]=1
}

##convert to file
submission = submission[order(submission$id),c(1,2)]
write.csv(submission,"submission.csv", row.names = FALSE)

#sub = read_csv('submission.csv')
#sub[sub$prediction==1,]

##(rechecking models)


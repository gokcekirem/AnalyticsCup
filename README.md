# AnalyticsCup
Data Analytics Project

This repository contains the code and extracts of the data for the 2020 Analytics Cup of Prof. Dr. Martin Bichler's _Business Analytics_ class at Technical University of Manhheim.
Participating teams were asked to devise a classification model that predicts whether a phyician of the dataset had an ownership interests (i.e., held shares) of a pharmaceutical company which they have received payments from.

The main challenge of the task was to engineer useful features that have predicte power over the target variable. Therefore, the script mainly focuses on data aggregation and modeling instead of other performance enhancing methods such as model selection.

The trained model found in this repository was among the 15 best performing models submitted by all teams. It was awarded with the highest grade available (1.0). 

Please find below excerpts of the data. Unfortunately, the payment dataset can not be uploaded here as github's filesize limit does not allow files larger than 25MB.

## Data Overview
### Companies

|  Company_ID  | Name | State |Country |
| :----------: | :--: | :---: | :-----:|
|  1  | Pharisaik, Inc | MA | United States |
|  2  | Drug Dex, Inc | <em>NA</em> | Japan |
|  3  | Grampyan, Inc | <em>NA</em> | Denmark |

### Physicians

|  ID  | Set | First_Name | Middle_Name | Last_Name | Name_Suffix | City | State | Zip_Code | Country | Province | Primary_Specialty | License_State_1 | License_State_2 | License_State_3 | License_State_4 | License_State_5 |
| :--: |:---:| :---------:| :----------:| :--------:| :----------:| :---:| :----:| :------: | :-----: | :-------:| :----------------:| :--------------:| :--------------:| :--------------:| :--------------:| :--------------:|
| 1 | train | Jane | A | Doe | <em>NA</em> | DETROIT | AZ | 94218-2813 | UNITED STATES | <em>NA</em> | Dental Providers | AZ | PA | NY | NJ | <em>NA</em> |
| 2 | test | John | M | Doe | JR. | LOUISVILLE | MO | 33524-2049 | UNITED STATES | <em>NA</em> | <em>NA</em> | MO | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> |

### Payments

| Record_ID | Physician_ID | Company_ID | Total_Amount_of_Payment_USDollars | Date | Number_of_Payments | Form_of_Payment_or_Transfer_of_Value | Nature_of_Payment_or_Transfer_of_Value | City_of_Travel | State_of_Travel | Country_of_Travel | Ownership_Indicator | Third_Party_Receipient | Charity | Third_Party_Covered | Contextual_Information | Related_Product_Indicator | Product_Code_1 | Product_Code_2 | Product_Code_3 | Product_Type_1 | Product_Type_2 | Product_Type_3 | Product_Name_1 | Product_Name_2 | Product_Name_3 | Product_Category_1 | Product_Category_2 | Product_Category_3 |
| :---------: |:----------:| :---------:| :-------------------------------: |:----:| :-----------------:| :----------------------------------: |:--------------------------------------:| :-------------:| :--------------:| :----------------:| :------------------:| :--------------------: |:-------:| :------------------:| :--------------------: |:-------------------------:| :-------------:| :------------: |:--------------:| :-------------:| :-------------:| :-------------:| :-------------:| :-------------:| :-------------:| :-----------------:| :-----------------:| :-----------------:|
| 1 | 1 | 2 | 24.76 | 08/01/2013 | 1 | Cash or cash equivalent | Food and Beverage | <em>NA</em> | <em>NA</em> | <em>NA</em> | No | No Third Party | <em>NA</em> | <em>NA</em> | Informational Meal | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> | <em>NA</em> |
| 2 | 1 | 3 | 74.79 | 07/08/2014 | 1 | Cash or cash equivalent | Travel and Lodging | Larchmont | NY | United States | Yes | Individual | No | Yes | <em>NA</em> | Yes | 49708-754-41 | <em>NA</em> | <em>NA</em> | Drug | <em>NA</em> | <em>NA</em> | BROMSITE | <em>NA</em> | <em>NA</em> | Ophthalmology | <em>NA</em> | <em>NA</em> |
| 3 | 2 | 1 | 11.00 | 05/08/2019 | 1 | In-kind items and services | Consulting Fee | <em>NA</em> | <em>NA</em> | <em>NA</em> | Yes | Entity | No | Yes | Educational Program | Yes | 10631-096-15 | 10631-122-04 | 10631-094-30 | Drug | Drug | Drug | Halog | ULTRAVATE | HALOG | Dermatology | Dermatology | Dermatology |



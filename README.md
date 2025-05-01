# Building an End to End Machine Learning Workflow in Snowflake

In this Notebook ([on Container Runtime](https://docs.snowflake.com/developer-guide/snowflake-ml/notebooks-on-spcs)), we will develop a machine learning model that accurately predicts the "mortgage response" (e.g., loan approval, offer acceptance) based on borrower characteristics and loan details.

**Why is this important?**

- `Risk Management:` Lenders can better assess the risk of loan default.
- `Operational Efficiency:` Automating parts of the approval process.
- `Targeted Marketing:` Identifying potential borrowers more effectively.
- `Improved Customer Experience:` Streamlining the loan process.

We will showcase all the typical steps in a machine learning pipeline using native capabilities in Snowflake through this use case:

### 1. `FEATURE ENGINEERING:` Use [Snowflake Feature Store](https://docs.snowflake.com/en/developer-guide/snowflake-ml/feature-store/overview) to track engineered features
- Store feature defintions in a feature store for reproducible computation of ML features
      
### 2. `MODEL TRAINING:` Train models using OSS XGBoost and Snowflake ML APIs
- Baseline OSS XGboost
- XGBoost with optimal hyperparameters identified via [Snowflake ML Parallel Hyperparameter Optimization](https://docs.snowflake.com/en/developer-guide/snowflake-ml/container-hpo)

### 3. `MODEL LOGGING, INFERENCE, & EXPLAINABILITY:` Register models in [Snowflake Model Registry](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/overview)
- Explore model registry capabilities such as **metadata tracking, inference, and explainability**
- Compare model metrics on train/test set to identify any issues of model performance or overfitting
- Tag the best performing model version as 'default' version

### 4. `ML OBSERVABILITY:` Set up [Model Monitors](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/model-observability) to track 1 year of predicted and actual loan repayments
- **Compute performance metrics** such a F1, Precision, Recall
- **Inspect model drift** (i.e. how much has the average predicted repayment rate changed day-to-day)
- **Compare models** side-by-side to understand which model should be used in production
- Identify and understand **data issues**

### 5. `ML LINEAGE:` Track [data and model lineage](https://docs.snowflake.com/en/user-guide/ui-snowsight-lineage#ml-lineage) throughout
- View and understand
  - The **origin of the data** used for computed features
  - The **data used** for model training
  - The **available model versions** being monitored

### 6. `[OPTIONAL] DISTRIBUTED MODEL TRAINING & DEPLOYMENT`
- Distributed XGBoost via [Snowflake's Distributed Modeling Classes](https://docs.snowflake.com/en/developer-guide/snowpark-ml/reference/latest/modeling_distributors) - single node, multi-GPU and multi-node, multi-GPU
- [Deploy model to Snowpark Container Services](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/container) 

## Setup
1. Run `setup.sql` in a SQL Worksheet
1. Change role to `ATTENDEE ROLE`
2. Navigate to `Notebooks` > `E2E_ML_NOTEBOOK`
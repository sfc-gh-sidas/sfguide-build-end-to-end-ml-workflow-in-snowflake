-- Using ACCOUNTADMIN, create a new role for this exercise 
USE ROLE ACCOUNTADMIN;

-- Create or replace a warehouse with auto-suspend enabled
CREATE OR REPLACE WAREHOUSE E2E_MLOPS_WH
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE -- Consider enabling auto-resume for better usability
    INITIALLY_SUSPENDED = TRUE; -- Start in a suspended state to save costs

-- Set the active warehouse for subsequent operations
USE WAREHOUSE E2E_MLOPS_WH;

-- Get username
SET USERNAME = (SELECT CURRENT_USER());
SELECT $USERNAME;

-- Create the E2E_ML_ROLE 
CREATE OR REPLACE ROLE E2E_ML_ROLE;

-- Grant necessary permissions to create databases, compute pools, and service endpoints to new role
USE ROLE ACCOUNTADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE E2E_ML_ROLE; 
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT CREATE ROLE ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT CREATE APPLICATION ON ACCOUNT TO ROLE E2E_ML_ROLE;
GRANT IMPORT SHARE ON ACCOUNT TO ROLE E2E_ML_ROLE;

-- grant new role to user and switch to that role
GRANT ROLE E2E_ML_ROLE to USER identifier($USERNAME);
USE ROLE E2E_ML_ROLE;

-- Create or replace a Snowpark-optimized virtual warehouse for ML workloads
CREATE OR REPLACE WAREHOUSE E2E_ML_HOL_WAREHOUSE WITH
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 300 -- Consider a more appropriate auto-suspend time for ML workloads
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Create Database 
CREATE OR REPLACE DATABASE E2E_MLOPS_SUMMIT_PROD;

-- Create Schema
CREATE OR REPLACE SCHEMA DEFAULT_SCHEMA;

DROP COMPUTE POOL IF EXISTS CP_GPU_NV_S_4;

-- Create a GPU compute pool for NVIDIA S-series with 4 nodes
CREATE COMPUTE POOL IF NOT EXISTS CP_GPU_NV_S_4
  MIN_NODES = 4
  MAX_NODES = 4
  INSTANCE_FAMILY = GPU_NV_S
  INITIALLY_SUSPENDED = TRUE
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 300;

-- Using accountadmin, grant privilege to create network rules and integrations on newly created db
USE ROLE ACCOUNTADMIN;
GRANT CREATE NETWORK RULE ON SCHEMA DEFAULT_SCHEMA TO ROLE E2E_ML_ROLE;
USE ROLE E2E_ML_ROLE;

-- Create a network rule for PyPI access if it doesn't exist
CREATE OR REPLACE NETWORK RULE pypi_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('pypi.org:443', 'pypi.python.org:443', 'pythonhosted.org:443', 'files.pythonhosted.org:443'); -- Explicitly include port 443 for HTTPS

-- Create an external access integration for PyPI if it doesn't exist
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION pypi_access_integration
  ALLOWED_NETWORK_RULES = (pypi_network_rule)
  ENABLED = TRUE;

-- Create a broad network rule to allow all outbound traffic on ports 80 and 443 if it doesn't exist
CREATE OR REPLACE NETWORK RULE allow_all_rule
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('0.0.0.0:443', '0.0.0.0:80');

-- Create a broad external access integration allowing all outbound traffic if it doesn't exist
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION allow_all_integration
  ALLOWED_NETWORK_RULES = (allow_all_rule)
  ENABLED = TRUE;

-- Create an API integration with Github
CREATE OR REPLACE API INTEGRATION GITHUB_INTEGRATION_E2E_SNOW_MLOPS
   api_provider = git_https_api
   api_allowed_prefixes = ('https://github.com/')
   enabled = true
   comment='Git integration with Snowflake Demo Github Repository.';

-- Create the integration with the Github demo repository
CREATE OR REPLACE GIT REPOSITORY GITHUB_REPO_E2E_SNOW_MLOPS
   ORIGIN = 'https://github.com/sfc-gh-sidas/sfguide-build-end-to-end-ml-workflow-in-snowflake' 
   API_INTEGRATION = 'GITHUB_INTEGRATION_E2E_SNOW_MLOPS' 
   COMMENT = 'Github Repository';

-- Create an image repository if it doesn't exist
CREATE OR REPLACE IMAGE REPOSITORY my_inference_images;

USE ROLE ACCOUNTADMIN;
GRANT CREATE SERVICE ON SCHEMA E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA TO ROLE E2E_ML_ROLE;
-- Grant CREATE DYNAMIC TABLE privilege on the default schema to the E2E_ML_ROLE
GRANT CREATE DYNAMIC TABLE ON SCHEMA E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA TO ROLE E2E_ML_ROLE;

USE ROLE E2E_ML_ROLE;

-- Fetch most recent files from Github repository
ALTER GIT REPOSITORY GITHUB_REPO_E2E_SNOW_MLOPS FETCH;

-- Copy notebook into snowflake configure runtime settings
CREATE OR REPLACE NOTEBOOK E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.E2E_ML_NOTEBOOK
FROM '@E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.GITHUB_REPO_E2E_SNOW_MLOPS/branches/main/' 
MAIN_FILE = 'E2E_ML_NOTEBOOK.ipynb' 
QUERY_WAREHOUSE = E2E_ML_HOL_WAREHOUSE
RUNTIME_NAME = 'SYSTEM$GPU_RUNTIME' 
COMPUTE_POOL = 'CP_GPU_NV_S_4'
IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600;

CREATE OR REPLACE NOTEBOOK E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.E2E_ML_NOTEBOOK_DIST
FROM '@E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.GITHUB_REPO_E2E_SNOW_MLOPS/branches/main/' 
MAIN_FILE = 'E2E_ML_NOTEBOOK_DIST.ipynb' 
QUERY_WAREHOUSE = E2E_ML_HOL_WAREHOUSE
RUNTIME_NAME = 'SYSTEM$GPU_RUNTIME' 
COMPUTE_POOL = 'CP_GPU_NV_S_4'
IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600;

ALTER NOTEBOOK E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.E2E_ML_NOTEBOOK ADD LIVE VERSION FROM LAST;
ALTER NOTEBOOK E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.E2E_ML_NOTEBOOK SET EXTERNAL_ACCESS_INTEGRATIONS = ( 'pypi_access_integration', 'allow_all_integration');

ALTER NOTEBOOK E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.E2E_ML_NOTEBOOK_DIST ADD LIVE VERSION FROM LAST;
ALTER NOTEBOOK E2E_MLOPS_SUMMIT_PROD.DEFAULT_SCHEMA.E2E_ML_NOTEBOOK_DIST SET EXTERNAL_ACCESS_INTEGRATIONS = ( 'pypi_access_integration', 'allow_all_integration');

--DONE! Now you can access your newly created notebook with your E2E_ML_ROLE and run through the end-to-end workflow!
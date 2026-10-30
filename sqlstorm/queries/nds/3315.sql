
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
CustomerAddress AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
QualifiedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        COALESCE(d.cd_gender, 'U') AS gender,
        COALESCE(d.cd_marital_status, 'U') AS marital_status,
        COALESCE(d.cd_education_status, 'Unknown') AS education_status,
        COALESCE(a.ca_city, 'Unknown') AS city,
        COALESCE(a.ca_state, 'Unknown') AS state,
        COALESCE(a.ca_country, 'Unknown') AS country,
        r.total_returns,
        r.total_return_amt,
        d.cd_purchase_estimate
    FROM 
        customer c
    LEFT OUTER JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT OUTER JOIN CustomerAddress a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT OUTER JOIN CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
)
SELECT 
    city,
    state,
    country,
    COUNT(DISTINCT c.customer_name) AS num_customers,
    SUM(total_return_amt) AS total_return_amount,
    AVG(total_returns) AS average_returns_per_customer,
    MAX(cd_purchase_estimate) AS highest_purchase_estimate
FROM 
    QualifiedCustomers c
GROUP BY 
    city, state, country
HAVING 
    COUNT(DISTINCT c.customer_name) > 10
ORDER BY 
    total_return_amount DESC
LIMIT 50;

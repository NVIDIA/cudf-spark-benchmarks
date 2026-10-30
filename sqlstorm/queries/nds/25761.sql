
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_quantity) AS total_returned_items,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AggregatedReturns AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_id) AS num_customers,
        SUM(total_returns) AS total_returns,
        SUM(total_returned_items) AS total_returned_items,
        SUM(total_returned_amount) AS total_returned_amount
    FROM 
        RankedCustomers
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
OverallStatistics AS (
    SELECT 
        'Overall' AS category,
        COUNT(c_customer_id) AS num_customers,
        SUM(total_returns) AS total_returns,
        SUM(total_returned_items) AS total_returned_items,
        SUM(total_returned_amount) AS total_returned_amount
    FROM 
        RankedCustomers
)
SELECT 
    category,
    num_customers,
    total_returns,
    total_returned_items,
    total_returned_amount
FROM 
    OverallStatistics
UNION ALL
SELECT 
    CONCAT(cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status) AS category,
    num_customers,
    total_returns,
    total_returned_items,
    total_returned_amount
FROM 
    AggregatedReturns
ORDER BY 
    num_customers DESC, total_returns DESC;

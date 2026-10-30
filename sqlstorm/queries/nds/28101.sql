
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesOverview AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
CustomerAnalytics AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        so.total_profit,
        so.transaction_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesOverview so ON cd.c_customer_sk = so.ss_customer_sk
),
FilteredCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank
    FROM 
        CustomerAnalytics
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    total_profit,
    transaction_count
FROM 
    FilteredCustomers
WHERE 
    profit_rank <= 5
ORDER BY 
    cd_gender, total_profit DESC;

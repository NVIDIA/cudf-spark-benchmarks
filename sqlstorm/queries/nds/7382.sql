
WITH RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3))
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
SalesAndDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.c_email_address,
        rds.total_quantity,
        rds.total_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer cs
    JOIN 
        RecentSales rds ON cs.c_customer_sk = rds.ws_bill_customer_sk
    JOIN 
        CustomerDemographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    csd.c_first_name,
    csd.c_last_name,
    csd.c_email_address,
    csd.total_quantity,
    csd.total_net_paid,
    csd.cd_gender,
    csd.cd_marital_status,
    csd.cd_purchase_estimate,
    CASE 
        WHEN csd.total_net_paid > 1000 THEN 'High Value'
        WHEN csd.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesAndDemographics csd
WHERE 
    csd.cd_marital_status = 'M' 
ORDER BY 
    csd.total_net_paid DESC
LIMIT 100;

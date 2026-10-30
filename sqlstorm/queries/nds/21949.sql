
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        COUNT(DISTINCT sr_item_sk) AS total_returns,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned_quantity
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
ReturnAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        SUM(CASE 
            WHEN cs.total_returns > 0 THEN cs.total_returned_quantity * -1 
            ELSE NULL 
        END) AS net_returns,
        COUNT(CASE 
            WHEN cs.total_returns = 0 THEN 1 
            ELSE NULL 
        END) AS customers_no_returns
    FROM 
        CustomerStats AS cs
    GROUP BY 
        cs.c_customer_sk
),
HighestPurchasers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.cd_gender,
        cs.purchase_rank
    FROM 
        CustomerStats AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.purchase_rank = 1
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    ra.net_returns,
    ra.customers_no_returns,
    COALESCE(ra.net_returns / NULLIF(ra.customers_no_returns, 0), 0) AS average_return_rate,
    TRIM(CONCAT('Customer: ', h.c_first_name, ' ', h.c_last_name)) AS customer_full_name,
    CASE 
        WHEN h.cd_gender = 'M' THEN 'Male'
        WHEN h.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description
FROM 
    HighestPurchasers AS h
LEFT JOIN 
    ReturnAnalysis AS ra ON h.c_customer_sk = ra.c_customer_sk
ORDER BY 
    average_return_rate DESC NULLS LAST;

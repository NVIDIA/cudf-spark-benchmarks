
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER(PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerWithDemo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SuspiciousReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS suspicious_quantity
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 10
    GROUP BY 
        sr_item_sk
)
SELECT 
    COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS customer_name,
    COALESCE(SUM(ss.ss_quantity), 0.00) AS total_quantity_sold,
    COALESCE(RR.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(RR.total_returns, 0) > 100 THEN 'High Return Rate'
        WHEN COALESCE(RR.total_returns, 0) BETWEEN 50 AND 100 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    RankedReturns RR ON ss.ss_item_sk = RR.sr_item_sk
JOIN 
    CustomerWithDemo cd ON c.c_customer_sk = cd.c_customer_sk
LEFT JOIN 
    SuspiciousReturns SR ON SR.sr_item_sk = ss.ss_item_sk
WHERE 
    cd.gender_rank = 1
AND 
    (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL OR cd.cd_purchase_estimate IS NOT NULL)
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    RR.total_returns
HAVING 
    SUM(ss.ss_quantity) > 0
ORDER BY 
    total_quantity_sold DESC NULLS LAST;

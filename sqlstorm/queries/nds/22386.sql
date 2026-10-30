
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        RANK() OVER (ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    sr.return_rank,
    ss.total_quantity_sold,
    ss.total_profit,
    COALESCE(NULLIF(ss.total_orders, 0), -1) AS order_count_adjusted,
    CASE 
        WHEN ss.total_profit IS NULL THEN 'No Profit' 
        WHEN ss.total_profit < 0 THEN 'Loss' 
        ELSE 'Profit' 
    END AS profit_status
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedReturns sr ON ci.c_customer_sk = sr.sr_item_sk
FULL OUTER JOIN 
    SalesSummary ss ON ss.ws_item_sk = sr.sr_item_sk
WHERE 
    (ci.marital_status = 'Married' AND ss.total_profit > 100) 
    OR (ci.marital_status = 'Single' AND ss.total_profit < 0)
    OR (ci.marital_status IS NULL AND ss.total_orders IS NOT NULL)
ORDER BY 
    profit_status DESC, ci.c_last_name ASC, ci.c_first_name ASC;

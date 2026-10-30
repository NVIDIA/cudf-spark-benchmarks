
WITH RankedReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sr_store_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_store_sk
), CTE_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
), ReturnVsSales AS (
    SELECT 
        R.sr_store_sk,
        R.total_returns,
        R.total_return_amount,
        S.total_quantity_sold,
        COALESCE(S.total_sales, 0) AS total_sales,
        (R.total_return_amount / NULLIF(S.total_sales, 0)) * 100 AS return_percentage
    FROM RankedReturns R
    LEFT JOIN CTE_Sales S ON R.sr_store_sk = S.ws_item_sk
)
SELECT 
    A.ca_city,
    A.ca_state,
    RV.total_returns,
    RV.total_return_amount,
    RV.return_percentage
FROM 
    customer_address A
JOIN 
    ReturnVsSales RV ON A.ca_address_sk = RV.sr_store_sk
WHERE 
    RV.return_percentage > 10
ORDER BY 
    RV.return_percentage DESC
LIMIT 10;

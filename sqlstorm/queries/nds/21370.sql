
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerStatus AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_marital_status = 'S' AND cd_gender = 'F' THEN 'Single Female'
            WHEN cd_marital_status = 'S' AND cd_gender = 'M' THEN 'Single Male'
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Other'
        END AS marital_status,
        cd_purchase_estimate,
        (SELECT AVG(cd_dep_count) FROM customer_demographics WHERE cd_marital_status = 'M') AS avg_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ExtendedWebSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) + COALESCE(SUM(wr.wr_return_amt), 0) AS total_net_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND wr.wr_return_quantity > 0
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        ws.ws_item_sk
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            WHEN ib.ib_upper_bound IS NULL THEN 'No Upper Bound'
            ELSE CONCAT('$', CAST(ib.ib_lower_bound AS STRING), ' - $', CAST(ib.ib_upper_bound AS STRING))
        END AS income_range,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band ib
)
SELECT 
    cs.marital_status,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    SUM(cs.cd_purchase_estimate) AS total_purchase_estimate,
    ir.income_range,
    COALESCE(SUM(ew.total_net_profit), 0) AS total_web_net_profit
FROM 
    CustomerStatus cs
LEFT JOIN 
    ExtendedWebSales ew ON cs.c_customer_sk = ew.ws_item_sk
LEFT JOIN 
    IncomeRanges ir ON cs.cd_purchase_estimate BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
WHERE 
    cs.avg_dependent_count > (SELECT AVG(cd_dep_count) FROM customer_demographics)
GROUP BY 
    cs.marital_status, ir.income_range
ORDER BY 
    customer_count DESC, total_web_net_profit ASC
LIMIT 10 OFFSET 5;

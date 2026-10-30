
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
NegativeReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    WHERE sr_return_quantity < 0
    GROUP BY sr_item_sk
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    s.s_store_name,
    R.total_quantity_sold,
    R.avg_net_profit,
    COALESCE(N.total_returned, 0) AS total_returns,
    CASE 
        WHEN R.avg_net_profit > 100 THEN 'High Profit'
        WHEN R.avg_net_profit BETWEEN 50 AND 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN SalesData R ON c.c_customer_sk = R.ws_item_sk
LEFT JOIN NegativeReturns N ON R.ws_item_sk = N.sr_item_sk
JOIN store s ON c.c_current_addr_sk = s.s_store_sk
WHERE EXISTS (
    SELECT 1 
    FROM RankedReturns rr 
    WHERE rr.sr_customer_sk = c.c_customer_sk 
    AND rr.rnk = 1
)
AND cd.cd_gender IS NOT NULL
AND s.s_closed_date_sk IS NULL
ORDER BY profit_category, total_returns DESC;

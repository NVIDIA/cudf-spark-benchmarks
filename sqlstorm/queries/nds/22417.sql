
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year >= 2022)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank = 1
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.marital_status,
    ci.cd_gender,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    SUM(ts.ws_net_profit) AS total_net_profit,
    (SELECT AVG(ts2.ws_net_profit) 
     FROM TopSales ts2 
     WHERE ts2.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_category LIKE '%Anomaly%')
    ) AS avg_net_profit_anomalous_items
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopSales ts ON ci.c_customer_sk = ts.ws_item_sk
GROUP BY 
    ci.marital_status, 
    ci.cd_gender
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_net_profit DESC
LIMIT 10 OFFSET 0;

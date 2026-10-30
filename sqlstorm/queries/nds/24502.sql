
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_net_profit DESC) AS gender_rank,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_item_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL AND 
        cd.cd_gender IS NOT NULL
),
TopSales AS (
    SELECT 
        ws_item_sk,
        MAX(total_item_profit) AS max_profit
    FROM 
        SalesData
    GROUP BY 
        ws_item_sk
),
StoreSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_net_profit > 0
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.ws_sales_price,
    sd.ws_net_profit,
    ss.total_store_profit,
    CASE 
        WHEN sd.gender_rank = 1 THEN 'Highest Profit Gender'
        ELSE 'Other'
    END AS rank_label
FROM 
    SalesData sd
LEFT JOIN 
    TopSales ts ON sd.ws_item_sk = ts.ws_item_sk AND sd.total_item_profit = ts.max_profit
JOIN 
    StoreSales ss ON sd.ws_item_sk = ss.ss_item_sk
WHERE 
    (sd.ws_net_profit IS NOT NULL OR ss.total_store_profit IS NOT NULL) AND 
    (sd.ws_sales_price + COALESCE(ss.total_store_profit, 0)) > 100
ORDER BY 
    sd.ws_item_sk, sd.ws_net_profit DESC
LIMIT 10;

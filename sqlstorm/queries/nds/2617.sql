
WITH SalesData AS (
    SELECT 
        COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk) AS sold_date_sk,
        COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk) ORDER BY COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk) DESC) AS row_num
    FROM 
        web_sales ws 
        FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
        FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk),
        COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk)
),
TopSales AS (
    SELECT 
        item_sk,
        total_net_profit
    FROM 
        SalesData
    WHERE 
        row_num = 1
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ts.total_net_profit,
    CASE 
        WHEN ts.total_net_profit IS NULL THEN 'No Sales'
        WHEN ts.total_net_profit > 10000 THEN 'High'
        ELSE 'Medium'
    END AS profitability_category
FROM 
    item i
    LEFT JOIN TopSales ts ON i.i_item_sk = ts.item_sk
WHERE 
    (i.i_current_price IS NOT NULL AND i.i_current_price > 0) 
    OR (i.i_wholesale_cost IS NOT NULL AND i.i_wholesale_cost < i.i_current_price)
    OR ts.total_net_profit IS NOT NULL
ORDER BY 
    profitability_category DESC, total_net_profit DESC 
LIMIT 100;

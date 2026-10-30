
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    UNION ALL 
    SELECT 
        cs_item_sk,
        cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) as rn,
        SUM(cs_net_profit) OVER (PARTITION BY cs_item_sk) AS total_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021) 
        AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
recent_returns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        COALESCE(total_profit, 0) AS total_profit,
        COALESCE(total_returns, 0) AS total_returns
    FROM 
        item
    LEFT JOIN 
        (SELECT 
            ws_item_sk, 
            SUM(total_profit) AS total_profit 
         FROM 
            ranked_sales 
         WHERE 
            rn = 1 
         GROUP BY 
            ws_item_sk) AS profits ON item.i_item_sk = profits.ws_item_sk
    LEFT JOIN 
        recent_returns ON item.i_item_sk = recent_returns.sr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.total_profit,
    id.total_returns,
    CASE 
        WHEN id.total_profit > 1000 AND id.total_returns < 5 THEN 'High Performer'
        WHEN id.total_profit < 500 AND id.total_returns > 20 THEN 'Low Performer'
        ELSE 'Average Performer'
    END AS performance_category
FROM 
    item_details id
WHERE 
    (id.total_profit IS NOT NULL AND id.total_profit <> 0)
    OR (id.total_returns IS NOT NULL AND id.total_returns <> 0)
ORDER BY 
    id.total_profit DESC, 
    id.total_returns ASC;

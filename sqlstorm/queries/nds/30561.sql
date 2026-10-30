
WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(cs.cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC)
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs.cs_item_sk
),
ranked_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_net_profit,
        sd.total_orders,
        sd.item_rank
    FROM 
        sales_data sd
    WHERE 
        sd.total_net_profit IS NOT NULL
)

SELECT 
    ia.i_item_id,
    ia.i_item_desc,
    IAS.total_net_profit,
    COALESCE(CAST(IAS.total_orders AS STRING), '0') AS order_count,
    CASE 
        WHEN IAS.item_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular'
    END AS seller_status
FROM 
    item ia
LEFT JOIN 
    ranked_sales IAS ON ia.i_item_sk = IAS.ws_item_sk
WHERE 
    ia.i_current_price IS NOT NULL 
    AND ia.i_current_price > 10.00
ORDER BY 
    IAS.total_net_profit DESC NULLS LAST
LIMIT 100;

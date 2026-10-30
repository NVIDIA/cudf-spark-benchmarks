
WITH  sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, 
        ss_item_sk
),
ranked_sales AS (
    SELECT 
        d.d_date AS sale_date,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_profit,
        RANK() OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.total_profit DESC) AS profit_rank
    FROM 
        sales_summary ss
    JOIN 
        date_dim d ON ss.ws_ship_date_sk = d.d_date_sk
)
SELECT 
    r.sale_date,
    r.ws_item_sk,
    r.total_quantity,
    r.total_profit,
    CASE 
        WHEN r.profit_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM 
    ranked_sales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer c ON c.c_current_cdemo_sk = r.ws_item_sk
WHERE 
    (c.c_birth_year IS NULL OR c.c_birth_year < 1975) 
    AND i.i_current_price BETWEEN 20.00 AND 100.00
ORDER BY 
    r.sale_date, r.total_profit DESC
LIMIT 100;

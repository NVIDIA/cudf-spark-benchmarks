
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND
        i.i_current_price > 20.00
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        * 
    FROM 
        sales_data
    WHERE 
        sales_rank <= 10
),
store_sales_data AS (
    SELECT 
        ss.ss_item_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_sales_count,
        SUM(ss.ss_net_profit) AS store_total_net_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(s.total_sales_quantity, 0) AS total_web_sales_quantity,
    COALESCE(s.total_net_profit, 0) AS total_web_net_profit,
    ss.unique_sales_count,
    ss.store_total_net_profit
FROM 
    item i
LEFT JOIN 
    top_items s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    store_sales_data ss ON i.i_item_sk = ss.ss_item_sk
WHERE 
    i.i_brand = 'BrandA' OR 
    (ss.store_total_net_profit IS NOT NULL AND ss.store_total_net_profit > 1000)
ORDER BY 
    total_web_net_profit DESC, 
    unique_sales_count ASC;

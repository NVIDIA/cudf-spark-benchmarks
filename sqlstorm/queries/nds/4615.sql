
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
high_value_sales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM 
        ranked_sales r
    WHERE 
        r.rank <= 10
    GROUP BY 
        r.ws_item_sk
),
average_profit AS (
    SELECT 
        h.ws_item_sk,
        AVG(h.total_net_profit) AS avg_net_profit
    FROM 
        high_value_sales h
    GROUP BY 
        h.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        coalesce(a.ca_city, 'UNKNOWN') AS city,
        h.avg_net_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales w ON i.i_item_sk = w.ws_item_sk
    LEFT JOIN 
        customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        average_profit h ON i.i_item_sk = h.ws_item_sk
)
SELECT 
    d.i_product_name,
    d.city,
    d.avg_net_profit,
    CASE 
        WHEN d.avg_net_profit IS NULL THEN 'No sales'
        WHEN d.avg_net_profit > 1000 THEN 'High Value'
        WHEN d.avg_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    item_details d
WHERE 
    d.avg_net_profit IS NOT NULL
ORDER BY 
    d.avg_net_profit DESC;

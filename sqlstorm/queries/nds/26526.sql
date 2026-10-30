
WITH detailed_sales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk,
        i.i_item_desc,
        i.i_brand,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.d_date,
        ws.ws_sales_price,
        ws.ws_net_profit,
        LENGTH(i.i_item_desc) AS item_desc_length,
        CHAR_LENGTH(c.c_email_address) AS email_length,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
    AND 
        d.d_year = 2023
),
aggregated_sales AS (
    SELECT 
        full_name,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(item_desc_length) AS avg_item_desc_length,
        AVG(email_length) AS avg_email_length
    FROM 
        detailed_sales
    GROUP BY 
        full_name
)
SELECT 
    full_name,
    order_count,
    total_net_profit,
    avg_item_desc_length,
    avg_email_length,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Profit'
        WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM 
    aggregated_sales
ORDER BY 
    total_net_profit DESC
LIMIT 10;

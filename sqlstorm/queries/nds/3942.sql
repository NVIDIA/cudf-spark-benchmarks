
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
top_sales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_net_profit
    FROM 
        ranked_sales rs
    WHERE 
        rs.rnk <= 5
),
sales_info AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cs.cs_item_sk
),
customer_counts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        customer c 
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk
),
final_results AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_order_number,
        ts.ws_sales_price,
        ts.ws_net_profit,
        COALESCE(sc.order_count, 0) AS customer_order_count,
        si.total_net_profit
    FROM 
        top_sales ts
    LEFT JOIN 
        customer_counts sc ON ts.ws_order_number = sc.order_count
    LEFT JOIN 
        sales_info si ON ts.ws_item_sk = si.cs_item_sk
)
SELECT 
    fr.ws_item_sk,
    fr.ws_order_number,
    fr.ws_sales_price,
    fr.ws_net_profit,
    fr.customer_order_count,
    fr.total_net_profit,
    CASE 
        WHEN fr.customer_order_count > 10 THEN 'High Value'
        WHEN fr.customer_order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    final_results fr
WHERE 
    fr.total_net_profit IS NOT NULL
ORDER BY 
    fr.total_net_profit DESC, fr.ws_sales_price ASC
LIMIT 100;

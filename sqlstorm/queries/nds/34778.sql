
WITH  top_items AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_quantity DESC
    LIMIT 10
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS full_names
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM top_items)
    GROUP BY 
        c.c_customer_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_items_sold,
        AVG(ss.ss_sales_price) AS average_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_transactions
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_id AS customer_id,
    cs.total_orders,
    cs.total_spent,
    COALESCE(ss.total_items_sold, 0) AS total_items_sold,
    COALESCE(ss.average_price, 0) AS average_price
FROM 
    customer_sales cs
LEFT JOIN 
    store s ON cs.c_customer_sk = s.s_store_sk
LEFT JOIN 
    store_sales_summary ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)
ORDER BY 
    cs.total_spent DESC;

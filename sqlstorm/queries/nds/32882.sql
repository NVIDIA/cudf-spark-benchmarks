
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_orders AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(ws.total_quantity, 0) AS total_web_quantity,
        COALESCE(ss.total_quantity, 0) AS total_store_quantity
    FROM 
        customer c
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            SUM(ws_quantity) AS total_quantity
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN (
        SELECT 
            ss_customer_sk,
            SUM(ss_quantity) AS total_quantity
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) ss ON c.c_customer_sk = ss.ss_customer_sk
), 
date_range AS (
    SELECT 
        MIN(d_date_sk) AS start_date, 
        MAX(d_date_sk) AS end_date
    FROM 
        date_dim
    WHERE 
        d_year = 2023
), 
top_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.rank <= 10
)

SELECT 
    c.c_customer_id,
    c_orders.total_web_quantity, 
    c_orders.total_store_quantity,
    top_items.i_item_id,
    top_items.i_item_desc,
    top_items.total_quantity,
    top_items.total_sales,
    COALESCE(c_orders.total_web_quantity, 0) + COALESCE(c_orders.total_store_quantity, 0) AS total_purchases,
    CASE 
        WHEN COALESCE(c_orders.total_web_quantity, 0) >= COALESCE(c_orders.total_store_quantity, 0) THEN 'Web'
        ELSE 'Store'
    END AS preferred_channel
FROM 
    customer_orders c_orders
JOIN 
    customer c ON c_orders.c_customer_sk = c.c_customer_sk
JOIN 
    top_items ON c.c_customer_id LIKE '%' || SUBSTR(top_items.i_item_id, -1) || '%'
WHERE 
    c.c_birth_year BETWEEN (SELECT start_date FROM date_range) AND (SELECT end_date FROM date_range)
ORDER BY 
    total_purchases DESC;

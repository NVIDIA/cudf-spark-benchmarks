WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(sd.total_sales) AS total_customer_sales
    FROM 
        customer c
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.ws_item_sk  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_customer_sales,
        RANK() OVER (ORDER BY cs.total_customer_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_customer_sales > (SELECT AVG(total_customer_sales) FROM customer_sales)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_customer_sales,
    d.d_date AS sale_date,
    inv.inv_quantity_on_hand
FROM 
    top_customers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk IN (SELECT ws_item_sk FROM sales_data WHERE total_sales > 1000))
JOIN 
    inventory inv ON inv.inv_item_sk = tc.c_customer_sk  
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_customer_sales DESC;
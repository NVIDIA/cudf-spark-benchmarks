WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2462160 AND 2462526  
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS customer_total_sales
    FROM 
        web_sales w
    JOIN customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        w.ws_sold_date_sk BETWEEN 2462160 AND 2462526
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    ci.sales_rank,
    ci.ws_item_sk,
    ci.total_quantity,
    ci.total_sales,
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.customer_total_sales
FROM 
    top_items ci
JOIN 
    customer_sales cs ON ci.ws_item_sk = cs.c_customer_sk
WHERE 
    ci.sales_rank <= 10  
ORDER BY 
    ci.total_sales DESC;
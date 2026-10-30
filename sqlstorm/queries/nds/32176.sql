
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY 
        ws_item_sk
),
top_products AS (
    SELECT 
        i.i_item_id, 
        i.i_product_name, 
        ss.total_sales, 
        ss.total_orders,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS rn
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.sales_rank <= 10
),
customer_city AS (
    SELECT 
        ca_city, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
)
SELECT 
    tp.i_item_id,
    tp.i_product_name,
    tp.total_sales,
    cc.ca_city,
    cc.customer_count,
    tp.total_orders,
    COALESCE(NULLIF(tp.total_orders, 0), 1) AS safe_orders,
    tp.total_sales / COALESCE(NULLIF(tp.total_orders, 0), 1) AS average_sales_per_order
FROM 
    top_products tp
CROSS JOIN 
    customer_city cc
WHERE 
    tp.total_sales > 1000
ORDER BY 
    tp.total_sales DESC, 
    cc.customer_count DESC;

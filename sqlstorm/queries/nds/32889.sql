
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        d.d_year,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_item_sk, d.d_year
), 
top_sales AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales, 
        d_year
    FROM 
        sales_data
    WHERE 
        sales_rank <= 10
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales 
        JOIN customer c ON web_sales.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
address_info AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) as customer_count
    FROM 
        customer_address ca
        JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state
)
SELECT 
    s.d_year, 
    ts.ws_item_sk, 
    ts.total_quantity,
    ts.total_sales,
    ci.total_orders,
    ci.total_spent,
    ai.customer_count
FROM 
    top_sales ts
    FULL OUTER JOIN customer_info ci ON ts.ws_item_sk = ci.c_customer_sk
    FULL OUTER JOIN address_info ai ON ci.total_orders > 0
    JOIN (SELECT DISTINCT d_year FROM sales_data) s ON s.d_year = ts.d_year
WHERE 
    (ci.total_orders IS NOT NULL OR ai.customer_count IS NOT NULL)
    AND (ci.total_spent IS NOT NULL OR ts.total_sales > 500)
ORDER BY 
    s.d_year, ts.total_sales DESC;

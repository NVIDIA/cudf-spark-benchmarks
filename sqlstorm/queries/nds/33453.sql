
WITH  monthly_sales AS (
    SELECT
        d.d_date AS month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_date
),
top_customers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
),
popular_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        item i
    INNER JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    mc.month,
    mc.total_sales,
    tc.c_first_name,
    tc.c_last_name,
    pi.i_item_id,
    pi.i_item_desc,
    pi.total_quantity
FROM 
    monthly_sales mc
LEFT JOIN 
    top_customers tc ON mc.sales_rank <= 10
LEFT JOIN 
    popular_items pi ON pi.total_quantity > 100
WHERE 
    mc.total_sales IS NOT NULL
ORDER BY 
    mc.total_sales DESC, tc.total_spent DESC, pi.total_quantity DESC;


WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        r.total_sales,
        r.order_count
    FROM 
        ranked_sales AS r
    INNER JOIN 
        customer AS c ON c.c_customer_id = r.c_customer_id
    WHERE 
        r.rank_sales <= 10
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_warehouse_sales
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales AS customer_total_sales,
    tc.order_count AS customer_order_count,
    ws.total_warehouse_sales AS warehouse_total_sales
FROM 
    top_customers AS tc
JOIN 
    warehouse_sales AS ws ON ws.total_warehouse_sales > 100000 
ORDER BY 
    tc.total_sales DESC, 
    ws.total_warehouse_sales DESC;

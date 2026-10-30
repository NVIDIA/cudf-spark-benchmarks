
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), top_customers AS (
    SELECT 
        c_customer_id AS customer_id,
        c_first_name,
        c_last_name,
        total_quantity,
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
), warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.customer_id, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_quantity, 
    tc.total_sales, 
    ws.w_warehouse_id, 
    ws.total_net_profit
FROM 
    top_customers tc
JOIN 
    warehouse_sales ws ON ws.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w ORDER BY w.w_warehouse_sq_ft DESC LIMIT 1)
ORDER BY 
    tc.total_sales DESC, ws.total_net_profit DESC;

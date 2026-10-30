
WITH sales_data AS (
    SELECT 
        w.w_warehouse_name AS warehouse_name,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 
        AND d.d_moy IN (6, 7) 
    GROUP BY 
        w.w_warehouse_name, c.c_first_name, c.c_last_name
), ranked_sales AS (
    SELECT 
        warehouse_name,
        c_first_name,
        c_last_name,
        total_quantity,
        total_sales,
        avg_net_profit,
        RANK() OVER (PARTITION BY warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    warehouse_name,
    c_first_name,
    c_last_name,
    total_quantity,
    total_sales,
    avg_net_profit
FROM 
    ranked_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    warehouse_name, total_sales DESC;

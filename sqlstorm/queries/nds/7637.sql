
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        s.s_store_name,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store AS s ON w.w_warehouse_sk = s.s_store_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, 
        s.s_store_name, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_year, 
        d.d_month_seq
)
SELECT 
    year,
    month,
    ROUND(AVG(total_sales), 2) AS average_sales,
    ROUND(SUM(order_count), 0) AS total_orders
FROM 
    (SELECT
        d_year AS year,
        d_month_seq AS month,
        total_sales,
        order_count
     FROM 
        SalesData
    ) AS summarized_sales
GROUP BY 
    year,
    month
ORDER BY 
    year, 
    month;

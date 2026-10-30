
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.ss_sales_price,
        w.w_warehouse_name,
        dd.d_date AS sales_date,
        (
            SELECT 
                COUNT(DISTINCT wr_order_number) 
            FROM 
                web_returns 
            WHERE 
                wr_returning_customer_sk = c.c_customer_sk
        ) AS return_count,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS lower_full_name,
        UPPER(CONCAT(w.w_warehouse_name, ' ', dd.d_date)) AS warehouse_sales_date
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON s.ss_store_sk = w.w_warehouse_sk
    JOIN 
        date_dim dd ON s.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        s.ss_sales_price > 20.00 
        AND dd.d_year = 2023
)
SELECT 
    full_name,
    COUNT(*) AS total_sales,
    SUM(ss_sales_price) AS total_revenue,
    AVG(return_count) AS avg_returns,
    MAX(warehouse_sales_date) AS last_transaction_info
FROM 
    SalesData
GROUP BY 
    full_name, 
    c_customer_id,
    c_first_name,
    c_last_name,
    return_count,
    warehouse_sales_date
ORDER BY 
    total_revenue DESC
LIMIT 10;

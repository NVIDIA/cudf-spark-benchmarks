
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id AS warehouse_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        d.d_year,
        CASE 
            WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
            WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
            WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
            WHEN d.d_month_seq BETWEEN 10 AND 12 THEN 'Q4'
        END AS quarter
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id, c.c_first_name, c.c_last_name, d.d_year, 
        CASE 
            WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
            WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
            WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
            WHEN d.d_month_seq BETWEEN 10 AND 12 THEN 'Q4'
        END
)
SELECT 
    warehouse_id,
    c_first_name,
    c_last_name,
    total_sales,
    total_orders,
    avg_net_profit,
    quarter,
    RANK() OVER (PARTITION BY warehouse_id, quarter ORDER BY total_sales DESC) AS sales_rank
FROM 
    SalesData
WHERE 
    total_sales > 10000
ORDER BY 
    warehouse_id, quarter, sales_rank;

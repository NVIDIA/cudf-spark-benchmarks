
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        d.d_year,
        sm.sm_ship_mode_id
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, d.d_year, sm.sm_ship_mode_id
),
YearlySales AS (
    SELECT 
        d_year,
        sm_ship_mode_id,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(total_sales) AS sales_total,
        SUM(total_orders) AS orders_count,
        AVG(average_order_value) AS avg_order_value
    FROM 
        SalesSummary
    GROUP BY 
        d_year, sm_ship_mode_id
)
SELECT
    ys.d_year,
    ys.sm_ship_mode_id,
    ys.unique_customers,
    ys.sales_total,
    ys.orders_count,
    ys.avg_order_value,
    RANK() OVER (PARTITION BY ys.d_year ORDER BY ys.sales_total DESC) AS sales_rank
FROM 
    YearlySales ys
ORDER BY 
    ys.d_year, sales_rank;


WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        sm.sm_type,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_quantity > 0
),
AggregatedSales AS (
    SELECT 
        d_year,
        d_month_seq,
        d_week_seq,
        sm_type,
        w_warehouse_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_week_seq, sm_type, w_warehouse_name
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    sm_type,
    w_warehouse_name,
    total_quantity,
    total_sales,
    total_orders,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
FROM 
    AggregatedSales
ORDER BY 
    d_year, d_month_seq, total_sales DESC;

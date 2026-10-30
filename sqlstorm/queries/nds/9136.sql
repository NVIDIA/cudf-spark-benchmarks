
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ci.c_first_name,
        ci.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_day_name,
        ws.ws_sold_date_sk AS sale_date
    FROM 
        web_sales ws
    JOIN 
        customer ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND ws.ws_net_paid > 100
),
SalesSummary AS (
    SELECT
        d_year,
        d_month_seq,
        d_week_seq,
        d_day_name,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT CONCAT(c_first_name, ' ', c_last_name)) AS unique_customers
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_week_seq, d_day_name
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    d_day_name,
    total_quantity,
    total_orders,
    total_revenue,
    unique_customers,
    ROUND(total_revenue / NULLIF(total_orders, 0), 2) AS avg_revenue_per_order,
    ROUND(total_quantity / NULLIF(unique_customers, 0), 2) AS avg_quantity_per_customer
FROM 
    SalesSummary
ORDER BY 
    d_year, d_month_seq, d_week_seq, d_day_name;

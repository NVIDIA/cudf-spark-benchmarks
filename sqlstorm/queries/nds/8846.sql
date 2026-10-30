
WITH sales_data AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id
), avg_income AS (
    SELECT 
        cd.cd_credit_rating,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_credit_rating
)
SELECT 
    sd.w_warehouse_id,
    sd.total_sales,
    sd.total_orders,
    sd.unique_customers,
    sd.avg_net_paid,
    ai.cd_credit_rating,
    ai.avg_income_band
FROM 
    sales_data sd
JOIN 
    avg_income ai ON sd.unique_customers > 100
ORDER BY 
    sd.total_sales DESC
LIMIT 10;


WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(NULLIF(ws.ws_net_paid, 0), 1) AS adjusted_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 360
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        SUM(CASE WHEN price_rank = 1 THEN rs.adjusted_net_paid END) AS top_price_total,
        SUM(rs.ws_sales_price) / COUNT(DISTINCT rs.ws_order_number) AS avg_sales_price
    FROM 
        customer_data cs
    JOIN 
        ranked_sales rs ON cs.c_customer_sk = rs.ws_item_sk
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    cs.c_first_name, 
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.top_price_total, 0) AS top_price_total,
    CASE 
        WHEN ss.avg_sales_price IS NULL THEN 'No sales'
        WHEN ss.avg_sales_price > 100 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_status,
    COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
FROM 
    customer_data cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.c_customer_sk
LEFT JOIN 
    household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
WHERE 
    (cs.cd_marital_status = 'M' OR cs.cd_gender = 'F')
    AND (hd.hd_vehicle_count IS NULL OR hd.hd_vehicle_count > 0)
ORDER BY 
    cs.c_last_name, cs.c_first_name;

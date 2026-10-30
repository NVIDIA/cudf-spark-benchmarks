
WITH regional_sales AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023 
                                AND d.d_month_seq BETWEEN 6 AND 8)
    GROUP BY 
        w.w_warehouse_name
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    rs.w_warehouse_name,
    rs.total_sales,
    rs.total_orders,
    ROUND(rs.avg_order_value, 2) AS avg_order_value,
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
FROM 
    regional_sales rs
LEFT JOIN 
    customer_details cd ON cd.gender_rank <= 5
WHERE 
    rs.total_sales >= (SELECT AVG(total_sales) FROM regional_sales)
ORDER BY 
    rs.total_sales DESC, 
    cd.cd_marital_status IS NOT NULL, 
    cd.cd_gender DESC;

WITH sales_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        sm.sm_type AS shipping_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
        AND ws.ws_sold_date_sk BETWEEN 2458862 AND 2459199 
    GROUP BY 
        ws.ws_order_number, ws.ws_ship_mode_sk, sm.sm_type
),
ranked_summary AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY shipping_type ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        sales_summary
)
SELECT 
    shipping_type,
    COUNT(*) AS order_count,
    SUM(total_quantity) AS total_items_sold,
    SUM(total_revenue) AS total_revenue,
    AVG(avg_order_value) AS avg_order_value,
    MAX(revenue_rank) AS max_revenue_rank
FROM 
    ranked_summary
GROUP BY 
    shipping_type
ORDER BY 
    total_revenue DESC;
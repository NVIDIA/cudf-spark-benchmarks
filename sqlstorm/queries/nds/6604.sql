
WITH yearly_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
), 
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
shipping_mode AS (
    SELECT 
        sm.sm_type,
        AVG(ws.ws_ext_ship_cost) AS avg_shipping_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)

SELECT 
    y.d_year AS year,
    y.total_profit,
    y.total_orders,
    y.unique_customers,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_purchase_estimate,
    cd.total_dependents,
    sm.sm_type,
    sm.avg_shipping_cost
FROM 
    yearly_sales y
CROSS JOIN 
    customer_demographics cd
CROSS JOIN 
    shipping_mode sm
ORDER BY 
    y.d_year DESC, cd.cd_gender, cd.cd_marital_status, sm.sm_type;

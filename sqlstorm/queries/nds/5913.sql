
WITH sales_summary AS (
    SELECT 
        dt.d_year AS sales_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
    WHERE 
        dt.d_year >= 2020
    GROUP BY 
        dt.d_year
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_estimated_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.sales_year,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.average_profit,
    cs.cd_gender,
    cs.total_customers,
    cs.total_estimated_purchase,
    ws.w_warehouse_id,
    ws.total_inventory
FROM 
    sales_summary ss
CROSS JOIN 
    customer_summary cs
JOIN 
    warehouse_summary ws ON ws.total_inventory > 1000
ORDER BY 
    ss.sales_year DESC, 
    cs.total_customers DESC, 
    ws.total_inventory DESC;

WITH customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
        SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers,
        SUM(cd.cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
sales_summary AS (
    SELECT 
        time_dim.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim time_dim ON ws.ws_sold_date_sk = time_dim.d_date_sk
    GROUP BY 
        time_dim.d_year
),
inventory_summary AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.married_customers,
    cs.single_customers,
    cs.total_dependents,
    ss.d_year,
    ss.total_quantity_sold,
    ss.total_net_profit,
    ss.total_discount,
    ii.total_quantity_on_hand
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON cs.total_customers > 0
JOIN 
    inventory_summary ii ON 1 = 1 
ORDER BY 
    cs.cd_gender, ss.d_year DESC;
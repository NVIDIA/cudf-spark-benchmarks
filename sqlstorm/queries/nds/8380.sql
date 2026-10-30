
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        count(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk,
        hd.hd_buy_potential
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, 
        w.w_warehouse_name
),
sales_summary AS (
    SELECT 
        ws.ws_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_paid) AS total_web_revenue
    FROM web_sales ws
    GROUP BY ws.ws_warehouse_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.hd_income_band_sk,
    cs.hd_buy_potential,
    ws.total_web_sales,
    ws.total_web_revenue,
    ws.total_web_revenue / NULLIF(cs.total_orders, 0) AS avg_revenue_per_order,
    w.total_inventory
FROM customer_summary cs
LEFT JOIN sales_summary ws ON ws.ws_warehouse_sk = cs.hd_income_band_sk
LEFT JOIN warehouse_summary w ON w.w_warehouse_sk = cs.hd_income_band_sk
WHERE cs.total_spent > 1000
ORDER BY cs.total_spent DESC
LIMIT 100;

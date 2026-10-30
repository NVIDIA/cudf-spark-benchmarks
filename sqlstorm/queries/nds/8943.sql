
WITH CustomerSegments AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_dep_employed_count) AS avg_employed_dependents,
        AVG(cd_dep_college_count) AS avg_college_dependents
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE c_birth_year >= 1980
    GROUP BY cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales 
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(w.w_warehouse_sq_ft) AS avg_warehouse_size
    FROM inventory 
    JOIN warehouse w ON inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    ss.d_year,
    ss.d_month_seq,
    cs.total_customers,
    cs.total_purchase_estimate,
    cs.total_dependents,
    cs.avg_employed_dependents,
    cs.avg_college_dependents,
    ss.total_net_profit,
    ss.total_orders,
    ws.total_quantity_on_hand,
    ws.avg_warehouse_size
FROM CustomerSegments cs
JOIN SalesSummary ss ON cs.total_customers > 100
JOIN WarehouseStats ws ON cs.total_customers <= (SELECT MAX(total_customers) FROM CustomerSegments)
ORDER BY cs.cd_gender, cs.cd_marital_status, ss.d_year, ss.d_month_seq;

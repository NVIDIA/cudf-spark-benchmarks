
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        AVG(ss.ss_sales_price) AS avg_purchase_value,
        MAX(ss.ss_sales_price) AS max_purchase_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
DateRange AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_web_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, d.d_month_seq
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.purchase_count,
    dr.d_year,
    dr.d_month_seq,
    dr.total_orders,
    dr.total_web_sales,
    ws.w_warehouse_id,
    ws.distinct_items,
    ws.total_inventory
FROM CustomerStats cs
CROSS JOIN DateRange dr
JOIN WarehouseSummary ws ON ws.total_inventory > 1000
ORDER BY cs.total_spent DESC, dr.total_web_sales DESC;

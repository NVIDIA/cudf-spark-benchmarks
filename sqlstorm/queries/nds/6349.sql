
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
store_sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        AVG(ss.ss_sales_price) AS avg_sales_per_transaction
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    ws.total_inventory,
    ss.total_store_sales,
    ss.avg_sales_per_transaction
FROM 
    customer_summary cs
JOIN 
    warehouse_summary ws ON ws.total_inventory > 1000
JOIN 
    store_sales_summary ss ON ss.total_store_sales > 5000
WHERE 
    cs.cd_gender = 'F' 
    AND cs.total_orders > 5
ORDER BY 
    cs.total_spent DESC
LIMIT 50;

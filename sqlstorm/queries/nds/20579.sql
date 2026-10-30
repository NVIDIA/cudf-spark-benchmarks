
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_purchase_estimate,
        (
            SELECT COUNT(*) 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = rc.c_customer_sk
        ) AS order_count,
        (
            SELECT SUM(ws.ws_net_profit) 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = rc.c_customer_sk
        ) AS total_profit
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rnk <= 10
),
ProfiledCustomers AS (
    SELECT 
        hvc.c_customer_id,
        hvc.cd_gender,
        hvc.order_count,
        hvc.total_profit,
        CASE 
            WHEN hvc.total_profit IS NULL THEN 'No Profit' 
            WHEN hvc.total_profit > 1000 THEN 'High Profit' 
            ELSE 'Low Profit' 
        END AS profit_category
    FROM 
        HighValueCustomers hvc
)
SELECT 
    p.c_customer_id,
    p.cd_gender,
    COALESCE(p.order_count, 0) AS order_count,
    COALESCE(p.total_profit, 0) AS total_profit,
    p.profit_category,
    w.w_warehouse_name,
    CASE 
        WHEN w.w_warehouse_sq_ft IS NULL THEN 'No Size Info' 
        ELSE 'Size Available' 
    END AS size_info
FROM 
    ProfiledCustomers p
FULL OUTER JOIN 
    warehouse w ON p.order_count = w.w_warehouse_sk
WHERE 
    (p.profit_category = 'High Profit' OR w.w_warehouse_name IS NOT NULL)
ORDER BY 
    p.total_profit DESC, 
    p.c_customer_id;

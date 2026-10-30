WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown' 
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CombinedStats AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity,
        cs.total_spent,
        ws.total_orders,
        ws.total_profit,
        RANK() OVER (PARTITION BY cs.purchase_estimate_band ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerStats cs
    LEFT JOIN 
        WarehouseStats ws ON ws.total_profit > 1000
),
FinalResults AS (
    SELECT 
        c.*, 
        COALESCE(c.total_spent / NULLIF(c.total_quantity, 0), 0) AS avg_spent_per_item
    FROM 
        CombinedStats c
    WHERE 
        c.spending_rank <= 10
)
SELECT 
    EXTRACT(YEAR FROM cast('2002-10-01' as date)) AS report_year,
    f.c_first_name,
    f.c_last_name,
    f.total_quantity,
    f.total_spent,
    f.avg_spent_per_item,
    COALESCE(f.total_orders, 0) AS total_orders,
    COALESCE(f.total_profit, 0) AS total_profit
FROM 
    FinalResults f
ORDER BY 
    f.total_spent DESC;
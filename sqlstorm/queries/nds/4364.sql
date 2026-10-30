
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 6)
    GROUP BY 
        w.w_warehouse_name
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
CombinedData AS (
    SELECT 
        sd.w_warehouse_name,
        sd.total_orders,
        sd.total_net_profit AS warehouse_net_profit,
        cd.cd_gender,
        cd.total_net_profit AS customer_net_profit,
        COALESCE(sd.total_net_profit, 0) + COALESCE(cd.total_net_profit, 0) AS combined_net_profit
    FROM 
        SalesData sd
    FULL OUTER JOIN 
        CustomerData cd ON cd.cd_gender IS NOT NULL
)
SELECT 
    w_warehouse_name AS w_name,
    total_orders,
    warehouse_net_profit,
    cd_gender,
    customer_net_profit,
    combined_net_profit
FROM 
    CombinedData
WHERE 
    (warehouse_net_profit IS NOT NULL OR customer_net_profit IS NOT NULL)
ORDER BY 
    combined_net_profit DESC
LIMIT 10;

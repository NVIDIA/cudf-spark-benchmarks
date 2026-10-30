
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_tax) AS total_return_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
), CombinedStats AS (
    SELECT 
        cs.c_customer_id,
        cs.total_returns,
        cs.total_return_amount,
        cs.total_return_tax,
        cs.total_orders,
        cs.total_net_profit,
        ws.warehouse_sales
    FROM 
        CustomerStats cs
    JOIN 
        WarehouseSales ws ON cs.total_orders > 0
)
SELECT 
    c_customer_id,
    total_returns,
    total_return_amount,
    total_return_tax,
    total_orders,
    total_net_profit,
    warehouse_sales,
    (total_net_profit - total_return_amount) AS net_profit_after_returns
FROM 
    CombinedStats
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;

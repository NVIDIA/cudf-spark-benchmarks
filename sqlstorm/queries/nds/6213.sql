
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
), 
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
), 
SalesDetails AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_sk,
    cs.total_net_profit,
    cs.total_orders,
    di.customer_count,
    di.avg_purchase_estimate,
    sd.total_quantity,
    sd.avg_order_value
FROM 
    CustomerSales cs
JOIN 
    DemographicInfo di ON cs.c_customer_sk = di.cd_demo_sk
JOIN 
    SalesDetails sd ON sd.total_quantity > 100
ORDER BY 
    cs.total_net_profit DESC
LIMIT 50;

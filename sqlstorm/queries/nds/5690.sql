
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_net_profit,
        cs.total_orders,
        cs.avg_order_value
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_net_profit > 1000
),
TopItems AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
)
SELECT 
    hvc.c_customer_id,
    hvc.total_net_profit,
    hvc.total_orders,
    hvc.avg_order_value,
    ti.i_item_id,
    ti.total_quantity_sold
FROM 
    HighValueCustomers hvc
JOIN 
    TopItems ti ON ti.total_quantity_sold > 50
ORDER BY 
    hvc.total_net_profit DESC;

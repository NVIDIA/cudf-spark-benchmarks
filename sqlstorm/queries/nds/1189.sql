
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(CASE 
                WHEN cd.cd_gender = 'M' THEN ws.ws_net_paid_inc_tax 
                ELSE 0 
            END) AS avg_spent_male,
        AVG(CASE 
                WHEN cd.cd_gender = 'F' THEN ws.ws_net_paid_inc_tax 
                ELSE 0 
            END) AS avg_spent_female
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > 1000
),
OrderDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        sm.sm_type AS shipping_type
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_order_number, sm.sm_type
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    hsc.spending_rank,
    od.total_quantity,
    od.total_sales,
    od.shipping_type
FROM 
    HighSpendingCustomers hsc
LEFT JOIN 
    CustomerStats cs ON hsc.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    OrderDetails od ON hsc.c_customer_sk = od.ws_order_number
WHERE 
    (od.total_quantity IS NOT NULL AND od.total_sales > 100)
ORDER BY 
    hsc.spending_rank, cs.total_spent DESC;


WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_addr_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent,
        SUM(ws.ws_quantity) AS total_items
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        sd.order_count,
        sd.total_spent,
        sd.avg_spent,
        sd.total_items
    FROM 
        CustomerData cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
    WHERE 
        cd.rn = 1 AND 
        sd.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                SalesData
        )
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.order_count,
    hvc.total_spent,
    hvc.avg_spent,
    COALESCE(hvc.total_items, 0) AS total_items,
    CASE 
        WHEN hvc.total_spent > 1000 THEN 'High Value'
        WHEN hvc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;


WITH CustomerCount AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
QualifiedCustomers AS (
    SELECT 
        cc.c_customer_sk,
        cc.total_orders,
        cc.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cc.total_orders ORDER BY cc.total_profit DESC) AS rank
    FROM 
        CustomerCount cc
    WHERE 
        cc.total_orders > 0
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(qc.total_orders, 0) AS total_orders,
    COALESCE(qc.total_profit, 0) AS total_profit,
    CASE 
        WHEN qc.rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    customer cu
LEFT JOIN 
    QualifiedCustomers qc ON cu.c_customer_sk = qc.c_customer_sk
WHERE 
    (cu.c_birth_year > 1980 AND cu.c_birth_year <= 1995)
    OR cu.c_preferred_cust_flag = 'Y'
ORDER BY 
    total_profit DESC
LIMIT 50;

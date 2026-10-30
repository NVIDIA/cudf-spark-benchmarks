
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        IB.ib_lower_bound,
        IB.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band IB ON hd.hd_income_band_sk = IB.ib_income_band_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    COUNT(p.c_customer_sk) AS customer_count,
    AVG(p.total_spent) AS avg_spent,
    MAX(p.total_orders) AS max_orders
FROM 
    CustomerPurchases p
JOIN 
    Demographics d ON p.c_customer_sk = d.cd_demo_sk
WHERE 
    p.total_spent > 1000
GROUP BY 
    d.cd_gender, d.cd_marital_status
ORDER BY 
    customer_count DESC
LIMIT 10;

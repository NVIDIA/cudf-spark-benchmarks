
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent_per_order,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_spent_per_order,
        cs.cd_gender,
        cs.marital_status,
        cs.income_band,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerStats cs
)
SELECT 
    rc.*,
    CASE 
        WHEN rc.total_orders > 10 THEN 'Frequent'
        WHEN rc.total_orders BETWEEN 1 AND 10 THEN 'Occasional'
        ELSE 'New'
    END AS customer_type
FROM 
    RankedCustomers rc
WHERE 
    rc.rank <= 100
ORDER BY 
    rc.total_spent DESC
LIMIT 50;

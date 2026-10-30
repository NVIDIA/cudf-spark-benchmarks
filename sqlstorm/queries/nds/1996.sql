
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.hd_income_band_sk,
        RANK() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    CASE 
        WHEN tc.rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS customer_category
FROM 
    TopCustomers tc
WHERE 
    tc.total_orders > 0
    AND tc.total_spent IS NOT NULL
    AND tc.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
ORDER BY 
    tc.hd_income_band_sk, tc.total_spent DESC;

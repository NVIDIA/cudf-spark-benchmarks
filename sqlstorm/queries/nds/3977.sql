
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
TopCustomers AS (
    SELECT * 
    FROM RankedCustomers 
    WHERE rn <= 5
),
SalesAggregates AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        sa.total_spent,
        sa.total_orders
    FROM TopCustomers tc
    LEFT JOIN SalesAggregates sa ON tc.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT 
    cs.c_first_name || ' ' || cs.c_last_name AS customer_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.total_orders, 0) AS total_orders,
    DENSE_RANK() OVER (ORDER BY COALESCE(cs.total_spent, 0) DESC) AS spending_rank,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No purchases'
        WHEN cs.total_spent > 5000 THEN 'High Spender'
        ELSE 'Regular Spender'
    END AS customer_category
FROM CustomerSales cs
WHERE cs.total_orders IS NOT NULL
ORDER BY spending_rank;

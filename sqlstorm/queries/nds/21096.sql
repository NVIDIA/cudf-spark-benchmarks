
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2022 AND 
        (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S' OR cd.cd_purchase_estimate IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, d.d_date, cd.cd_gender, cd.cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        c.c_customer_id,
        total_spent,
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY total_spent DESC) AS rnk,
        RANK() OVER (ORDER BY total_spent DESC) AS sales_rank
    FROM CustomerDetails c
    WHERE total_spent IS NOT NULL
),
MaxSales AS (
    SELECT
        c.c_customer_id,
        MAX(total_spent) AS max_spent
    FROM SalesAnalysis c
    GROUP BY c.c_customer_id
)
SELECT 
    s.c_customer_id,
    s.total_spent,
    s.total_orders,
    s.sales_rank,
    MAX(s2.max_spent) AS max_sales,
    CASE 
        WHEN s.total_spent IS NULL THEN 'NO SPENDING'
        WHEN s.total_orders > 10 THEN 'HIGH SPENDER'
        ELSE 'AVERAGE SPENDER'
    END AS spending_category
FROM SalesAnalysis s
LEFT JOIN MaxSales s2 ON s.c_customer_id = s2.c_customer_id
GROUP BY s.c_customer_id, s.total_spent, s.total_orders, s.sales_rank
HAVING (s.total_spent > 1000 OR s.total_orders > 5)
ORDER BY s.total_spent DESC, s.sales_rank;

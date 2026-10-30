WITH  SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30 days')
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sd.ws_order_number) AS order_count,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE total_spent IS NOT NULL
)
SELECT 
    rc.c_customer_id,
    rc.total_spent,
    rc.spending_rank,
    CASE 
        WHEN rc.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM RankedCustomers rc
WHERE rc.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
ORDER BY rc.total_spent DESC
LIMIT 100;
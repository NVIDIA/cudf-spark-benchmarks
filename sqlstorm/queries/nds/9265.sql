
WITH CustomerPurchaseData AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueCustomers AS (
    SELECT 
        customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_spent,
        total_orders,
        distinct_items_purchased,
        NTILE(5) OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM CustomerPurchaseData
)
SELECT 
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    COUNT(*) AS number_of_customers,
    AVG(total_spent) AS avg_spending,
    AVG(total_orders) AS avg_orders,
    AVG(distinct_items_purchased) AS avg_distinct_items
FROM HighValueCustomers AS hvc
WHERE hvc.spend_rank = 1
GROUP BY hvc.cd_gender, hvc.cd_marital_status, hvc.cd_education_status
ORDER BY number_of_customers DESC;

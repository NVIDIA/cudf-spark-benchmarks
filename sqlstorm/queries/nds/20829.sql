WITH  DateCTE AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, 
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_month_seq) AS month_rank
    FROM date_dim
    WHERE d_year >= 1998
),
CustomerSales AS (
    SELECT c.c_customer_sk, c.c_customer_id, 
           COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT c.c_customer_id,
           DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank,
           cs.total_quantity, cs.total_orders, cs.total_spent
    FROM CustomerSales cs
    INNER JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT cd.cd_gender, cd.cd_marital_status,
       COUNT(tc.c_customer_id) AS rank_based_customers,
       AVG(tc.total_spent) AS avg_spent_per_customer,
       SUM(tc.total_quantity) AS total_items_purchased
FROM TopCustomers tc
JOIN CustomerDemographics cd ON tc.rank <= 10 AND cd.customer_count > 0
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY cd.cd_gender, cd.cd_marital_status;
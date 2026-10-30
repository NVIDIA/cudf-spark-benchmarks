
WITH CustomerOverview AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM CustomerOverview
),
CustomerShipping AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS web_orders,
        SUM(ws.ws_net_paid) AS total_web_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_education_status,
        tc.total_sales,
        tc.total_transactions,
        tc.avg_transaction_value,
        cs.web_orders,
        cs.total_web_spent
    FROM TopCustomers tc
    LEFT JOIN CustomerShipping cs ON tc.c_customer_sk = cs.c_customer_sk
    WHERE tc.sales_rank <= 10
)
SELECT 
    f.*,
    COALESCE(f.web_orders, 0) AS web_orders,
    COALESCE(f.total_web_spent, 0) AS total_web_spent,
    CASE 
        WHEN f.total_sales > 10000 THEN 'High Value Customer'
        WHEN f.total_sales > 5000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_segment
FROM FinalReport f
ORDER BY f.total_sales DESC;

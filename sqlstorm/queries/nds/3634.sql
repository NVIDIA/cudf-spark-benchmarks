
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM TopCustomers tc
LEFT JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE tc.sales_rank <= 10
  AND (cd.cd_gender = 'F' OR cd.cd_marital_status IS NULL)
ORDER BY tc.sales_rank;

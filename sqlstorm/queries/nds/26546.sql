
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_salutation, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        d.d_date
    FROM date_dim d
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
TopPurchasers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.total_spent,
        DENSE_RANK() OVER (ORDER BY ci.total_spent DESC) AS rank
    FROM CustomerInfo ci
)
SELECT 
    tp.full_name,
    tp.cd_gender,
    tp.cd_marital_status,
    tp.cd_education_status,
    tp.total_spent,
    tr.d_date
FROM TopPurchasers tp
CROSS JOIN DateRange tr
WHERE tp.rank <= 10
ORDER BY tp.total_spent DESC, tr.d_date;

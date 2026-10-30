
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM customer_summary cs
    WHERE cs.total_spent > 1000
)
SELECT 
    hv.c_customer_sk,
    hv.c_first_name,
    hv.c_last_name,
    hv.total_spent,
    hv.order_count,
    hv.rank,
    CASE 
        WHEN hv.rank <= 10 THEN 'Top Customer'
        WHEN hv.rank <= 50 THEN 'Valued Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM high_value_customers hv
ORDER BY hv.rank;

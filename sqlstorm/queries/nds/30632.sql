
WITH  Sales_Analysis AS (
    SELECT
        s.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) DESC) AS revenue_rank
    FROM
        store s
    LEFT JOIN
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY
        s.s_store_id
),
Customer_Insights AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        SUM(ss.ss_net_paid) AS total_spent,
        MAX(cd.cd_marital_status) AS marital_status,
        MAX(cd.cd_gender) AS gender,
        SUM(CASE WHEN cd.cd_dep_count IS NULL THEN 0 ELSE cd.cd_dep_count END) AS dependent_count
    FROM
        customer c
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    INNER JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_id
),
Top_Customers AS (
    SELECT
        ci.c_customer_id,
        ci.total_spent,
        ci.purchase_count,
        RANK() OVER (ORDER BY ci.total_spent DESC) AS customer_rank
    FROM
        Customer_Insights ci
    WHERE
        ci.purchase_count > 1
)
SELECT
    sa.s_store_id,
    sa.total_sales,
    sa.total_revenue,
    COALESCE(tc.total_spent, 0) AS top_customer_spent,
    COALESCE(tc.purchase_count, 0) AS top_customer_purchases
FROM
    Sales_Analysis sa
LEFT JOIN
    Top_Customers tc ON tc.customer_rank = 1
WHERE
    sa.total_sales > 10
ORDER BY
    sa.total_revenue DESC;


WITH RecursiveSales AS (
    SELECT 
        ss_store_sk, 
        ss_item_sk, 
        ss_ticket_number, 
        ss_quantity, 
        ss_net_paid, 
        ss_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_quantity DESC) as sale_rank
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
    )
), 
CustomerSummary AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(ss.ss_net_paid) AS total_spent, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.cd_gender, 
        cs.total_spent, 
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) as gender_rank 
    FROM CustomerSummary cs
)
SELECT 
    tcs.c_customer_id, 
    tcs.cd_gender, 
    tcs.total_spent,
    rs.ss_store_sk, 
    rs.ss_item_sk, 
    rs.ss_ticket_number, 
    rs.ss_quantity, 
    rs.ss_net_paid
FROM TopCustomers tcs
JOIN RecursiveSales rs ON tcs.gender_rank <= 5
WHERE 
    tcs.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerSummary 
        WHERE cd_gender = tcs.cd_gender
    )
ORDER BY tcs.cd_gender, tcs.total_spent DESC, rs.ss_net_paid DESC;


WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_credit_rating IN ('Great', 'Good')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA'
        AND ss.ss_sold_date_sk > (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
    GROUP BY 
        ss.ss_store_sk
),
RankedStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.total_transactions,
        ss.total_store_sales,
        ROW_NUMBER() OVER (ORDER BY ss.total_store_sales DESC) AS store_rank
    FROM 
        store s
    JOIN StoreSales ss ON s.s_store_sk = ss.ss_store_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.order_count,
    ci.total_spent,
    rs.s_store_name,
    rs.total_transactions,
    rs.total_store_sales
FROM 
    CustomerInfo ci
FULL OUTER JOIN RankedStores rs ON ci.gender_rank = rs.store_rank
WHERE 
    (ci.total_spent IS NOT NULL OR rs.total_transactions IS NOT NULL)
ORDER BY 
    COALESCE(ci.total_spent, 0) DESC, 
    COALESCE(rs.total_store_sales, 0) DESC;


WITH CustomerRevenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) DESC) AS revenue_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cr_count.return_count,
        cr_count.promotion_count,
        cr_count.total_disc,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY total_disc DESC) AS city_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            cr_returning_customer_sk,
            COUNT(*) AS return_count,
            SUM(cs_ext_discount_amt) AS total_disc,
            COUNT(DISTINCT cs_promo_sk) AS promotion_count
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk
        GROUP BY cr_returning_customer_sk
    ) cr_count ON c.c_customer_sk = cr_count.cr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.ca_city,
        tc.cd_gender,
        tc.cd_marital_status,
        COALESCE(tr.total_revenue, 0) AS total_revenue,
        tc.return_count,
        tc.promotion_count,
        tc.city_rank,
        CASE 
            WHEN tc.return_count IS NULL THEN 'No Returns' 
            ELSE 'Has Returns' 
        END AS return_status
    FROM TopCustomers tc
    LEFT JOIN CustomerRevenue tr ON tc.c_customer_sk = tr.c_customer_sk
)
SELECT 
    fre.c_customer_sk,
    fre.ca_city,
    fre.cd_gender,
    fre.cd_marital_status,
    FRE.total_revenue,
    FRE.return_count,
    CASE 
        WHEN fre.return_status = 'No Returns' THEN NULL 
        ELSE fre.promotion_count 
    END AS effective_promotion_count,
    DENSE_RANK() OVER (ORDER BY fre.total_revenue DESC) AS rank_overall,
    LEAD(total_revenue) OVER (ORDER BY fre.total_revenue DESC) AS next_customer_revenue
FROM FinalReport fre
WHERE fre.city_rank = 1
AND fre.return_status IS NOT NULL
OR fre.total_revenue > 1000.00
ORDER BY fre.total_revenue DESC;

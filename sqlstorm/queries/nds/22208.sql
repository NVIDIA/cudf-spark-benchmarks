WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
      AND cd.cd_gender IS NOT NULL
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= cast('2002-10-01' as date) - INTERVAL '1 year'
    GROUP BY ws.ws_bill_customer_sk
),
CustomerPromotions AS (
    SELECT 
        rc.c_customer_sk,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count
    FROM RankedCustomers rc
    LEFT JOIN web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY rc.c_customer_sk
),
SalesSummary AS (
    SELECT 
        r.c_customer_sk,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(cp.promo_count, 0) AS promo_count,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(cp.promo_count, 0) = 0 THEN 'No Promotions'
            ELSE 'Active Customer'
        END AS customer_status
    FROM RankedCustomers r
    LEFT JOIN RecentSales rs ON r.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN CustomerPromotions cp ON r.c_customer_sk = cp.c_customer_sk
)
SELECT 
    s.*,
    ROW_NUMBER() OVER (PARTITION BY s.customer_status ORDER BY s.total_sales DESC) AS sales_rank,
    CASE
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM SalesSummary s
WHERE s.customer_status != 'No Sales'
ORDER BY s.customer_status, sales_rank;
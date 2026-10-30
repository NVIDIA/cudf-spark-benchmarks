
WITH TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
PromotionalSales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_paid_inc_ship_tax) AS promo_total_sales,
        COUNT(cs_order_number) AS promo_order_count
    FROM catalog_sales
    WHERE cs_promo_sk IS NOT NULL
    GROUP BY cs_bill_customer_sk
),
CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(TS.total_sales, 0) AS total_web_sales,
        COALESCE(PS.promo_total_sales, 0) AS total_promo_sales,
        (COALESCE(TS.total_sales, 0) + COALESCE(PS.promo_total_sales, 0)) AS combined_sales,
        CASE 
            WHEN COALESCE(TS.total_sales, 0) > 0 THEN 'Web Customer'
            ELSE 'Non-Web Customer'
        END AS customer_type
    FROM customer c
    LEFT JOIN TotalSales TS ON c.c_customer_sk = TS.ws_bill_customer_sk
    LEFT JOIN PromotionalSales PS ON c.c_customer_sk = PS.cs_bill_customer_sk
)
SELECT 
    co.customer_type,
    COUNT(DISTINCT co.c_customer_sk) AS customer_count,
    AVG(co.total_web_sales) AS avg_web_sales,
    AVG(co.total_promo_sales) AS avg_promo_sales,
    AVG(co.combined_sales) AS avg_combined_sales
FROM CustomerOrders co
GROUP BY co.customer_type
HAVING AVG(co.combined_sales) > 1000
UNION
SELECT 
    'Total',
    COUNT(DISTINCT co.c_customer_sk),
    AVG(co.total_web_sales),
    AVG(co.total_promo_sales),
    AVG(co.combined_sales)
FROM CustomerOrders co
WHERE co.combined_sales IS NOT NULL;

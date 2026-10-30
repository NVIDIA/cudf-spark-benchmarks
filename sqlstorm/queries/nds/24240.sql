
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(w.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT w.ws_order_number) AS web_order_count,
        COUNT(DISTINCT s.ss_ticket_number) AS store_order_count,
        AVG(s.ss_sales_price) AS avg_store_sales_price
    FROM customer c
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_ship_customer_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_month IS NULL)
    GROUP BY c.c_customer_sk
), FilteredDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating IS NOT NULL
      AND cd.cd_gender = 'M'
      AND (cd.cd_purchase_estimate > (SELECT AVG(cd2.cd_purchase_estimate) FROM customer_demographics cd2) 
           OR cd.cd_marital_status IS NULL)
), SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        fd.cd_gender,
        fd.cd_purchase_estimate
    FROM CustomerSales cs
    JOIN FilteredDemographics fd ON cs.c_customer_sk = fd.cd_demo_sk
    WHERE cs.total_web_sales > 1000
)
SELECT 
    COALESCE(ss.c_customer_sk, 0) AS customer_sk,
    SUM(ss.total_web_sales) AS total_sales,
    SUM(ss.web_order_count) AS total_orders,
    COUNT(DISTINCT fd.cd_gender) AS unique_genders
FROM SalesSummary ss
FULL OUTER JOIN FilteredDemographics fd ON ss.c_customer_sk = fd.cd_demo_sk
WHERE (fd.cd_purchase_estimate IS NOT NULL AND fd.cd_purchase_estimate < 3000)
   OR (ss.total_web_sales IS NULL AND ss.web_order_count IS NULL)
GROUP BY ss.c_customer_sk
HAVING AVG(ss.total_web_sales) > 1500 OR COUNT(ss.web_order_count) > 5
ORDER BY total_sales DESC
LIMIT 10;

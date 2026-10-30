
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) + COUNT(DISTINCT cs.cs_order_number) + COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_current_cdemo_sk
),
DemographicStats AS (
    SELECT
        cd.cd_demo_sk,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_demographics cd
    GROUP BY
        cd.cd_demo_sk
),
SalesRanked AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        ds.max_purchase_estimate,
        ds.min_purchase_estimate,
        ds.avg_purchase_estimate
    FROM
        CustomerSales cs
    LEFT JOIN DemographicStats ds ON cs.c_current_cdemo_sk = ds.cd_demo_sk
)
SELECT
    sr.c_customer_sk,
    sr.total_sales,
    sr.sales_rank,
    CASE 
        WHEN sr.total_sales > (SELECT AVG(total_sales) FROM CustomerSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance,
    CONCAT('Total Sales: $', CAST(sr.total_sales AS VARCHAR(20))) AS formatted_sales,
    COALESCE(sr.max_purchase_estimate, 0) AS max_purchase_estimate,
    COALESCE(sr.min_purchase_estimate, 0) AS min_purchase_estimate,
    COALESCE(sr.avg_purchase_estimate, 0) AS avg_purchase_estimate
FROM
    SalesRanked sr
WHERE 
    sr.total_sales > 1000
ORDER BY 
    sr.sales_rank
LIMIT 10;

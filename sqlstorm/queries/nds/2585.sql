
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate > 5000
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sss.total_store_sales,
    sss.unique_customers,
    CASE 
        WHEN hvc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM HighValueCustomers hvc
LEFT JOIN CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
JOIN StoreSalesSummary sss ON sss.total_store_sales > (SELECT AVG(total_store_sales) FROM StoreSalesSummary)
WHERE hvc.total_sales IS NOT NULL
ORDER BY hvc.total_sales DESC, hvc.c_last_name ASC;

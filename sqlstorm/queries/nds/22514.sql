
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rnk <= 5
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        MAX(ss.ss_sold_date_sk) AS last_sale_date
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
CustomerStoreSales AS (
    SELECT 
        t.c_customer_sk,
        s.last_sale_date,
        s.total_sales,
        s.unique_customers
    FROM 
        TopCustomers t
    LEFT JOIN 
        StoreSalesSummary s ON s.ss_store_sk IN (
            SELECT s_store_sk 
            FROM store 
            WHERE s_country = 'USA' AND s_state IS NOT NULL
        )
)
SELECT 
    cs.c_customer_sk,
    cs.last_sale_date,
    COALESCE(cs.total_sales, 0) AS total_sales,
    CASE 
        WHEN cs.unique_customers IS NULL THEN 'N/A'
        WHEN cs.unique_customers > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    CONCAT(cs.c_customer_sk, '-', cs.last_sale_date) AS unique_id
FROM 
    CustomerStoreSales cs
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM StoreSalesSummary) 
    OR cs.unique_customers = (SELECT MAX(unique_customers) FROM StoreSalesSummary)
ORDER BY 
    cs.total_sales DESC, cs.c_customer_sk ASC
LIMIT 10;

WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_transactions,
        CASE 
            WHEN cs.total_web_sales IS NULL THEN 'No Web Sales'
            WHEN cs.total_catalog_sales IS NULL THEN 'No Catalog Sales'
            ELSE 'Both Sales'
        END AS sales_type
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        (cs.total_web_sales > 1000 OR cs.total_catalog_sales > 1000)
),
RankedHighValueCustomers AS (
    SELECT 
        hvc.c_customer_id,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_web_sales,
        hvc.total_catalog_sales,
        hvc.total_store_transactions,
        hvc.sales_type,
        ROW_NUMBER() OVER (PARTITION BY hvc.sales_type ORDER BY hvc.total_web_sales + hvc.total_catalog_sales DESC) AS rank
    FROM 
        HighValueCustomers hvc
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_transactions,
    r.sales_type
FROM 
    RankedHighValueCustomers r
WHERE 
    r.rank <= 10
ORDER BY 
    r.sales_type, r.total_web_sales + r.total_catalog_sales DESC;
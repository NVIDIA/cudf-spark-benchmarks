
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(CASE WHEN ws_ext_sales_price IS NOT NULL THEN ws_ext_sales_price ELSE 0 END), 0) AS total_web_sales,
        COALESCE(SUM(CASE WHEN cs_ext_sales_price IS NOT NULL THEN cs_ext_sales_price ELSE 0 END), 0) AS total_catalog_sales,
        COALESCE(SUM(CASE WHEN ss_ext_sales_price IS NOT NULL THEN ss_ext_sales_price ELSE 0 END), 0) AS total_store_sales,
        COUNT(DISTINCT ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
), 
SalesSummary AS (
    SELECT 
        c_customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        web_order_count,
        catalog_order_count,
        store_order_count,
        total_web_sales + total_catalog_sales + total_store_sales AS total_sales,
        CASE 
            WHEN (total_web_sales + total_catalog_sales + total_store_sales) > 0 THEN 1 
            ELSE 0 
        END AS is_active_customer
    FROM 
        CustomerSales
), 
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC NULLS LAST) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    RANK() OVER (ORDER BY total_sales DESC) AS overall_rank,
    c_customer_id,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    total_sales,
    CASE 
        WHEN total_sales IS NULL OR total_sales = 0 THEN 'Inactive' 
        ELSE 'Active' 
    END AS customer_status,
    CASE 
        WHEN is_active_customer = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS actively_engaged
FROM 
    RankedCustomers
WHERE 
    sales_rank <= 100
ORDER BY 
    overall_rank;


WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
RankedCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales c
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.total_web_sales, 
        c.total_catalog_sales, 
        c.total_store_sales,
        CASE 
            WHEN c.total_web_sales > c.total_catalog_sales 
                 AND c.total_web_sales > c.total_store_sales THEN 'Web'
            WHEN c.total_catalog_sales > c.total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END AS dominant_channel
    FROM 
        RankedCustomers c
    WHERE 
        c.sales_rank <= 10
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_web_sales,
    t.total_catalog_sales,
    t.total_store_sales,
    t.dominant_channel,
    CASE 
        WHEN t.dominant_channel = 'Web' THEN 'Highest impact customers for online campaigns'
        WHEN t.dominant_channel = 'Catalog' THEN 'Key targets for promotional catalogs'
        ELSE 'Focus on improving store experience'
    END AS marketing_message
FROM 
    TopCustomers t
ORDER BY 
    t.total_web_sales DESC, t.c_last_name ASC;

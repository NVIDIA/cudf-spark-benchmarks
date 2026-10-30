
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END), 0) AS total_web_sales,
        COALESCE(SUM(CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END), 0) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
DiscountedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_discount_amt, 0)) AS total_discounted_web_sales,
        SUM(COALESCE(cs.cs_ext_discount_amt, 0)) AS total_discounted_catalog_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        (ws.ws_ext_discount_amt > 0 OR cs.cs_ext_discount_amt > 0)
    GROUP BY 
        c.c_customer_id
),
FinalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        ds.total_discounted_web_sales,
        ds.total_discounted_catalog_sales,
        (cs.total_web_sales + cs.total_catalog_sales) AS overall_sales,
        (COALESCE(ds.total_discounted_web_sales, 0) + COALESCE(ds.total_discounted_catalog_sales, 0)) AS overall_discounted_sales,
        CASE WHEN (COALESCE(ds.total_discounted_web_sales, 0) + COALESCE(ds.total_discounted_catalog_sales, 0)) > 0 
            THEN (1.0 * (cs.total_web_sales + cs.total_catalog_sales) / (ds.total_discounted_web_sales + ds.total_discounted_catalog_sales)) 
            ELSE 1 END AS discount_factor
    FROM 
        CustomerSales cs
    LEFT JOIN DiscountedSales ds ON cs.c_customer_id = ds.c_customer_id
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_web_sales,
    f.total_catalog_sales,
    f.overall_sales,
    f.overall_discounted_sales,
    f.discount_factor,
    RANK() OVER (ORDER BY f.overall_sales DESC) AS sales_rank
FROM 
    FinalSales f
WHERE 
    f.discount_factor < 0.95
ORDER BY 
    f.discount_factor DESC, f.overall_sales DESC
LIMIT 100;

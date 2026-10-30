
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL AND 
        (c.c_current_cdemo_sk IS NOT NULL OR c.c_current_hdemo_sk IS NOT NULL)
    GROUP BY 
        c.c_customer_id
), RankedSales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        web_order_count,
        catalog_order_count,
        store_order_count,
        RANK() OVER (ORDER BY total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    r.customer_id,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.web_order_count,
    r.catalog_order_count,
    r.store_order_count,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    RankedSales r
WHERE 
    r.total_web_sales > 1000 OR r.total_catalog_sales > 1000 OR r.total_store_sales > 1000
ORDER BY 
    r.sales_rank
LIMIT 100;

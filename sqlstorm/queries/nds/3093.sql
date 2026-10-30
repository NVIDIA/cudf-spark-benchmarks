
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_ranking AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_sales + total_store_sales DESC) AS sales_rank
    FROM 
        customer_summary
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.web_order_count,
    cs.store_order_count,
    cs.catalog_return_count,
    CASE 
        WHEN cs.total_web_sales + cs.total_store_sales = 0 THEN 'No Sales' 
        ELSE 'Active' 
    END AS sales_status
FROM 
    sales_ranking cs
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.total_web_sales DESC, cs.total_store_sales DESC;

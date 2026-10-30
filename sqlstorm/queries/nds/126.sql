WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales, 
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
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
CTE_Ranked_Customers AS (
    SELECT 
        ccs.c_customer_sk, 
        ccs.c_first_name, 
        ccs.c_last_name, 
        ccs.total_web_sales + ccs.total_catalog_sales + ccs.total_store_sales AS total_sales,
        RANK() OVER (ORDER BY ccs.total_web_sales DESC) AS web_rank,
        RANK() OVER (ORDER BY ccs.total_catalog_sales DESC) AS catalog_rank,
        RANK() OVER (ORDER BY ccs.total_store_sales DESC) AS store_rank
    FROM 
        CTE_Customer_Sales ccs
)
SELECT 
    r.c_customer_sk, 
    r.c_first_name, 
    r.c_last_name, 
    r.total_sales, 
    r.web_rank, 
    r.catalog_rank, 
    r.store_rank
FROM 
    CTE_Ranked_Customers r
WHERE 
    r.total_sales > (
        SELECT AVG(total_sales) FROM CTE_Ranked_Customers
    )
ORDER BY 
    r.total_sales DESC
LIMIT 10;
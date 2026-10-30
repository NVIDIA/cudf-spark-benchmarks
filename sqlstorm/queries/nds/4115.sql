
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 1000 AND 
        cs.sales_rank <= 50
)
SELECT 
    fs.c_first_name || ' ' || fs.c_last_name AS customer_full_name,
    fs.total_spent,
    (SELECT COUNT(DISTINCT sr_item_sk) 
     FROM store_returns 
     WHERE sr_customer_sk = fs.c_customer_sk) AS total_returns,
    (SELECT COUNT(*) 
     FROM catalog_returns 
     WHERE cr_returning_customer_sk = fs.c_customer_sk) AS total_catalog_returns
FROM 
    FilteredSales fs
ORDER BY 
    fs.total_spent DESC;

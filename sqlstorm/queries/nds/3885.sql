
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) DESC) AS sales_rank
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year >= 1980 AND 
        (c.c_email_address LIKE '%@example.com' OR c.c_preferred_cust_flag = 'Y')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales) FROM CustomerSales
        )
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_sales,
    (SELECT COUNT(*) FROM HighSpenders) AS total_high_spenders,
    CASE 
        WHEN hs.total_sales > 1000 THEN 'VIP'
        ELSE 'Regular'
    END AS customer_type
FROM 
    HighSpenders hs
ORDER BY 
    hs.total_sales DESC
LIMIT 10;

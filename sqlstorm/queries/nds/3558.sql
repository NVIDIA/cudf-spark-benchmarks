
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        RANK() OVER (ORDER BY (cs.total_store_sales + cs.total_web_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_customer_sk = cs.c_customer_sk
)
SELECT 
    sr.c_first_name,
    sr.c_last_name,
    COALESCE(sr.total_store_sales, 0) AS store_sales,
    COALESCE(sr.total_web_sales, 0) AS web_sales,
    sr.sales_rank,
    COALESCE((SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = sr.c_customer_sk), 0) AS total_store_returns,
    COALESCE((SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = sr.c_customer_sk), 0) AS total_web_returns
FROM 
    SalesRanking sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;

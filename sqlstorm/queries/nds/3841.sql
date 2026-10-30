
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        (COALESCE(SUM(ws.ws_net_paid), 0) + COALESCE(SUM(cs.cs_net_paid), 0) + COALESCE(SUM(ss.ss_net_paid), 0)) AS total_sales
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_web_sales,
        c.total_catalog_sales,
        c.total_store_sales,
        c.total_sales,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
),
IncomeBandSales AS (
    SELECT 
        h.hd_income_band_sk,
        SUM(sr.total_sales) AS band_total_sales
    FROM 
        SalesRank sr
        INNER JOIN household_demographics h ON sr.c_customer_sk = h.hd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(b.band_total_sales, 0) AS total_sales_for_band,
    (SELECT 
         COUNT(*) 
     FROM 
         SalesRank sr 
     WHERE 
         sr.total_sales > 1000) AS above_threshold_count
FROM 
    income_band ib
    LEFT JOIN IncomeBandSales b ON ib.ib_income_band_sk = b.hd_income_band_sk
ORDER BY 
    ib.ib_lower_bound;

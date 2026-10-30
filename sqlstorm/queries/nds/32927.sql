
WITH  SalesCTE AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
TopSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(d.d_month_seq, 0) AS month_seq,
        COALESCE(d.d_year, 0) AS year,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS web_sales_total,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS catalog_sales_total
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk OR d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_month_seq, d.d_year
), 
NullLogicBenchmark AS (
    SELECT 
        t.c_customer_id,
        t.c_first_name,
        t.c_last_name,
        t.month_seq,
        t.year,
        t.web_sales_total,
        t.catalog_sales_total,
        RANK() OVER (ORDER BY (t.web_sales_total + t.catalog_sales_total) DESC) as combined_rank
    FROM 
        TopSales t
    WHERE 
        (t.web_sales_total > 1000 OR t.catalog_sales_total > 1000) 
        AND (t.month_seq IS NULL OR t.year IS NULL)
)
SELECT 
    n.c_customer_id,
    n.c_first_name,
    n.c_last_name,
    n.month_seq,
    n.year,
    COALESCE(n.web_sales_total, 0) AS total_web_sales,
    COALESCE(n.catalog_sales_total, 0) AS total_catalog_sales,
    n.combined_rank
FROM 
    NullLogicBenchmark n
WHERE 
    n.combined_rank <= 10
ORDER BY 
    n.combined_rank;

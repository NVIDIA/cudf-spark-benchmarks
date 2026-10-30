
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cs.total_web_sales + cs.total_catalog_sales, 0) DESC) AS ranking
    FROM 
        customer c
    LEFT JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
),
income_summary AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        h.hd_income_band_sk
),
date_comparison AS (
    SELECT 
        dd.d_year,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        date_dim dd
    LEFT JOIN 
        store_sales ss ON ss.ss_sold_date_sk = dd.d_date_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_catalog_sales,
    isb.customer_count,
    isb.total_net_profit,
    dc.total_store_profit,
    dc.total_web_profit
FROM 
    top_customers tc
JOIN 
    income_summary isb ON tc.c_customer_sk = isb.hd_income_band_sk
JOIN 
    date_comparison dc ON EXTRACT(YEAR FROM DATE '2002-10-01') = dc.d_year
WHERE 
    tc.ranking <= 10
ORDER BY 
    tc.total_web_sales DESC, tc.total_catalog_sales DESC;

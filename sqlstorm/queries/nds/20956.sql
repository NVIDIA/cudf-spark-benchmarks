
WITH  customer_loyalty AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
customer_income AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN (ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL) 
            THEN NULL 
            ELSE ib.ib_upper_bound - ib.ib_lower_bound 
        END AS income_range,
        cd.cd_marital_status
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
date_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    cl.c_customer_id,
    ci.income_range,
    ds.d_year,
    ds.total_sales,
    ds.sales_rank,
    CASE 
        WHEN cl.total_purchases IS NULL THEN 'NEW_CUSTOMER'
        WHEN cl.total_purchases > 10 THEN 'LOYAL_CUSTOMER'
        ELSE 'CASUAL_CUSTOMER'
    END AS customer_status
FROM 
    customer_loyalty cl
JOIN 
    customer_income ci ON ci.cd_demo_sk = cl.c_customer_sk
JOIN 
    date_summary ds ON ds.d_year = EXTRACT(YEAR FROM CAST('2002-10-01' AS DATE))
WHERE 
    ds.sales_rank <= 5 AND
    (ci.income_range IS NOT NULL OR ci.cd_marital_status = 'S')
ORDER BY 
    ds.total_sales DESC,
    cl.c_customer_id
LIMIT 10 OFFSET 5;

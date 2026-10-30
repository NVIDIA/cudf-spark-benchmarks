WITH CTE_CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL 
        AND ws.ws_sold_date_sk > (
            SELECT 
                MAX(d.d_date_sk) 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2001
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        MAX(h.hd_income_band_sk) AS max_income_band
    FROM 
        household_demographics h
    GROUP BY 
        h.hd_demo_sk
),
CTE_StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk = (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_date = cast('2002-10-01' as date)
        )
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'Platinum'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier,
    COALESCE(ss.total_store_sales, 0) AS store_sales_today,
    1.0 * cs.total_sales / NULLIF(ss.total_store_sales, 0) AS sales_ratio
FROM 
    CTE_CustomerSales cs
LEFT JOIN 
    CTE_StoreSales ss ON cs.c_customer_sk = ss.ss_store_sk
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
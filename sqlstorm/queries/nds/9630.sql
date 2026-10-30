
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        SalesSummary
)
SELECT 
    hd_income_band_sk,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_store_sales) AS avg_store_sales,
    SUM(CASE WHEN web_sales_rank <= 10 THEN 1 ELSE 0 END) AS top_web_customers,
    SUM(CASE WHEN store_sales_rank <= 10 THEN 1 ELSE 0 END) AS top_store_customers
FROM 
    RankedSales
GROUP BY 
    hd_income_band_sk
ORDER BY 
    hd_income_band_sk;

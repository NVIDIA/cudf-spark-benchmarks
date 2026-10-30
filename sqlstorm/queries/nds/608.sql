
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.purchase_count,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.hd_income_band_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesDemographics sd
)
SELECT 
    rs.c_customer_sk,
    rs.total_sales,
    rs.purchase_count,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.hd_income_band_sk,
    rs.hd_buy_potential,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        WHEN rs.total_sales < 100 THEN 'Low Value'
        WHEN rs.total_sales BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS sales_category
FROM 
    RankedSales rs
WHERE 
    (rs.sales_rank <= 5 OR rs.hd_buy_potential IS NOT NULL)
ORDER BY 
    rs.hd_income_band_sk, rs.sales_rank;

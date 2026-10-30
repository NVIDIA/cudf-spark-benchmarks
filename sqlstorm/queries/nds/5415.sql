
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CD.cd_gender,
        HD.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, CD.cd_gender, HD.hd_income_band_sk
),
CustomerRanking AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales, 
        cs.order_count,
        RANK() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_sales DESC) AS sales_rank,
        cs.hd_income_band_sk
    FROM 
        CustomerSales cs
)
SELECT 
    cr.c_customer_sk, 
    cr.c_first_name, 
    cr.c_last_name, 
    cr.total_sales, 
    cr.order_count, 
    cr.sales_rank, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
FROM 
    CustomerRanking cr
JOIN 
    income_band ib ON cr.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.hd_income_band_sk, cr.sales_rank;

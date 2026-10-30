
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CD.cd_gender,
        HD.hd_income_band_sk
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        household_demographics AS HD ON CD.cd_demo_sk = HD.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id, CD.cd_gender, HD.hd_income_band_sk
), CustomerRankings AS (
    SELECT 
        ccs.c_customer_id,
        ccs.total_sales,
        ccs.cd_gender,
        ccs.hd_income_band_sk,
        RANK() OVER (PARTITION BY ccs.cd_gender, ccs.hd_income_band_sk ORDER BY ccs.total_sales DESC) AS sales_rank
    FROM 
        RankedCustomerSales AS ccs
)
SELECT 
    cr.c_customer_id,
    cr.total_sales,
    cr.cd_gender,
    cr.hd_income_band_sk,
    cr.sales_rank
FROM 
    CustomerRankings AS cr
WHERE 
    cr.sales_rank <= 5
ORDER BY 
    cr.cd_gender, 
    cr.hd_income_band_sk, 
    cr.total_sales DESC;

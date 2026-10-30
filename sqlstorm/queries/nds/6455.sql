
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        hd.hd_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        hd.hd_income_band_sk
),
SalesSummary AS (
    SELECT 
        customer_info.c_customer_sk,
        customer_info.c_first_name,
        customer_info.c_last_name,
        customer_info.cd_gender,
        customer_info.cd_marital_status,
        customer_info.cd_credit_rating,
        customer_info.hd_income_band_sk,
        RANK() OVER (PARTITION BY customer_info.hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank,
        customer_info.total_sales
    FROM 
        CustomerInfo customer_info
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.cd_credit_rating,
    ib.ib_lower_bound AS income_band_lower,
    ib.ib_upper_bound AS income_band_upper,
    ss.total_sales
FROM 
    SalesSummary ss
JOIN 
    income_band ib ON ss.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ss.sales_rank <= 10
ORDER BY 
    ss.hd_income_band_sk ASC, 
    ss.total_sales DESC;

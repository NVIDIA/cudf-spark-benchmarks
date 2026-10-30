
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 90 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.hd_income_band_sk,
        RANK() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_sales DESC) as income_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.order_count,
    r.cd_gender,
    r.cd_marital_status,
    r.hd_income_band_sk,
    (SELECT COUNT(*) FROM RankedSales WHERE income_rank <= 10 AND hd_income_band_sk = r.hd_income_band_sk) AS top_sales_count
FROM 
    RankedSales r
WHERE 
    r.income_rank <= 10
ORDER BY 
    r.hd_income_band_sk, r.total_sales DESC;

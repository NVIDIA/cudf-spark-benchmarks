
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
)
SELECT 
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_sales,
    sr.order_count,
    sr.sales_rank,
    cd.cd_marital_status,
    cd.cd_gender,
    hd.hd_income_band_sk
FROM 
    SalesRanked AS sr
JOIN 
    customer_demographics AS cd ON sr.c_customer_sk = cd.cd_demo_sk
JOIN 
    household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
WHERE 
    sr.sales_rank <= 10 AND
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M')
ORDER BY 
    sr.total_sales DESC, sr.c_last_name;

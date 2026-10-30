
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
), RankedSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.c_email_address,
        sh.total_sales,
        RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        SalesHierarchy sh
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.c_email_address,
    r.total_sales,
    r.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    RankedSales r
LEFT JOIN 
    CustomerDemographics cd ON r.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;

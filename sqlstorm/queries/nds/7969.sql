WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450500 
    GROUP BY 
        ws_bill_customer_sk
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        rd.ib_lower_bound,
        rd.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band rd ON hd.hd_income_band_sk = rd.ib_income_band_sk
), SalesWithDetails AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_sales,
        r.order_count,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.ib_lower_bound,
        c.ib_upper_bound
    FROM 
        RankedSales r
    JOIN 
        CustomerDetails c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    swd.c_first_name,
    swd.c_last_name,
    swd.cd_gender,
    swd.cd_marital_status,
    swd.cd_education_status,
    swd.total_sales,
    swd.order_count
FROM 
    SalesWithDetails swd
ORDER BY 
    swd.total_sales DESC
LIMIT 20;
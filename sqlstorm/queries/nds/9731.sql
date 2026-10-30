WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458849 AND 2459480 
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        r.total_sales, 
        r.order_count
    FROM 
        customer c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.sales_rank <= 10
),
DemographicData AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        d.cd_gender,
        d.cd_marital_status
    FROM 
        household_demographics h
    JOIN 
        customer_demographics d ON h.hd_demo_sk = d.cd_demo_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    dd.cd_gender,
    dd.cd_marital_status,
    hvc.total_sales,
    hvc.order_count
FROM 
    HighValueCustomers hvc
JOIN 
    DemographicData dd ON hvc.c_customer_sk = dd.hd_demo_sk
ORDER BY 
    hvc.total_sales DESC;
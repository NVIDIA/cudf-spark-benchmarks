WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459896 AND 2460565  
    GROUP BY 
        ws_bill_customer_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.total_sales,
        r.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ib_income_band_sk
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        r.sales_rank <= 10  
)
SELECT 
    c.ca_country,
    COUNT(tc.ws_bill_customer_sk) AS top_customer_count,
    AVG(tc.total_sales) AS avg_sales_per_customer,
    MAX(tc.total_sales) AS max_sales,
    MIN(tc.total_sales) AS min_sales
FROM 
    TopCustomers tc
JOIN 
    customer_address c ON tc.ws_bill_customer_sk = c.ca_address_sk
GROUP BY 
    c.ca_country
ORDER BY 
    top_customer_count DESC;

WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        TRIM(ca_country) AS country_cleaned
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.country_cleaned
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq
),
CustomerSales AS (
    SELECT 
        cu.full_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        CustomerDetails cu
    JOIN 
        web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cu.full_name, cu.cd_gender, cu.cd_marital_status, cu.cd_education_status
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_sales,
    ms.d_month_seq,
    ms.total_sales AS monthly_sales
FROM 
    CustomerSales cs
JOIN 
    MonthlySales ms ON cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC, ms.d_month_seq;

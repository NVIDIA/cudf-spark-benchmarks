WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        c_email_address,
        c_birth_year,
        da.full_address,
        CASE 
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year < 18 THEN 'Minor'
            WHEN EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year BETWEEN 18 AND 65 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group
    FROM 
        customer c
    JOIN 
        AddressDetails da ON c.c_current_addr_sk = da.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.customer_name,
    cd.c_email_address,
    cd.full_address,
    cd.age_group,
    d.gender_marital_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(sd.avg_sales, 0) AS avg_sales
FROM 
    CustomerDetails cd
LEFT JOIN 
    Demographics d ON cd.c_customer_sk = d.cd_demo_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.age_group = 'Adult'
ORDER BY 
    total_sales DESC, order_count DESC;
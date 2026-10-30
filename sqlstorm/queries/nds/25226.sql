
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date_sk, 
        d_date, 
        d_month_seq, 
        d_year, 
        d_day_name
    FROM 
        date_dim
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    dd.d_date,
    dd.d_month_seq,
    dd.d_year,
    SUM(CASE 
            WHEN s.ss_quantity > 0 THEN 1 
            ELSE 0 
        END) AS total_sales,
    COUNT(DISTINCT s.ss_ticket_number) AS unique_transactions
FROM 
    store_sales s
JOIN 
    AddressDetails ad ON s.ss_addr_sk = ad.ca_address_sk
JOIN 
    CustomerDetails cd ON s.ss_customer_sk = cd.c_customer_sk
JOIN 
    DateDetails dd ON s.ss_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    ad.full_address, 
    cd.full_name, 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    dd.d_date, 
    dd.d_month_seq, 
    dd.d_year
ORDER BY 
    dd.d_date, 
    ad.full_address;

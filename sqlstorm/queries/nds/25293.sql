
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnsStatistics AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesStatistics AS (
    SELECT 
        ss_customer_sk,
        COUNT(*) AS total_sales,
        SUM(ss_sales_price) AS total_sales_amt
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    COALESCE(rs.return_count, 0) AS total_returns,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rs.total_returned_amt, 0) AS total_returned_amt,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_sales_amt, 0) AS total_sales_amt
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    ReturnsStatistics rs ON cd.c_customer_sk = rs.sr_customer_sk
LEFT JOIN 
    SalesStatistics ss ON cd.c_customer_sk = ss.ss_customer_sk
WHERE 
    ad.ca_state = 'NY' 
    AND cd.cd_gender = 'F'
ORDER BY 
    cd.full_name;


WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerGender AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS gender_count
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
DateCounts AS (
    SELECT 
        d_year, 
        COUNT(d_date_sk) AS date_count
    FROM 
        date_dim
    GROUP BY 
        d_year
),
Combined AS (
    SELECT 
        AC.ca_city,
        GC.cd_gender,
        DC.d_year,
        AC.address_count,
        GC.gender_count,
        DC.date_count
    FROM 
        AddressCounts AC
    CROSS JOIN 
        CustomerGender GC
    CROSS JOIN 
        DateCounts DC
)
SELECT 
    ca_city,
    cd_gender,
    d_year,
    address_count,
    gender_count,
    date_count,
    CONCAT(ca_city, ' - ', cd_gender, ' - ', d_year) AS combined_string,
    LENGTH(CONCAT(ca_city, ' - ', cd_gender, ' - ', d_year)) AS string_length
FROM 
    Combined
WHERE 
    LENGTH(CONCAT(ca_city, ' - ', cd_gender, ' - ', d_year)) > 50
ORDER BY 
    LENGTH(CONCAT(ca_city, ' - ', cd_gender, ' - ', d_year)) DESC;

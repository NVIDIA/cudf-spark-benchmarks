
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        SUM(CASE WHEN ca_state = 'CA' THEN 1 ELSE 0 END) AS ca_address_count,
        SUM(CASE WHEN ca_country = 'USA' THEN 1 ELSE 0 END) AS usa_address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerGenderCount AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesDetails AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.ca_address_count,
    ac.usa_address_count,
    cg.cd_gender,
    cg.gender_count,
    sd.total_sales,
    sd.total_quantity,
    sd.total_profit
FROM 
    AddressCounts ac
JOIN 
    CustomerGenderCount cg ON ac.address_count > 100
JOIN 
    SalesDetails sd ON sd.total_sales > 50000
ORDER BY 
    ac.ca_city, cg.cd_gender;

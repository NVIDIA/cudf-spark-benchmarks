
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        SUM(LENGTH(ca_street_number) + LENGTH(ca_street_name) + LENGTH(ca_street_type) + LENGTH(ca_city)) AS total_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_education_status LIKE '%Graduate%' THEN 1 ELSE 0 END) AS graduate_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateDetails AS (
    SELECT 
        d_year, 
        d_month_seq, 
        COUNT(*) AS total_dates
    FROM 
        date_dim
    WHERE 
        d_year >= 2020
    GROUP BY 
        d_year, d_month_seq
),
SalesSummary AS (
    SELECT 
        ws_item_sk, 
        COUNT(ws_order_number) AS sales_count, 
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    A.ca_state, 
    A.address_count, 
    A.total_length,
    C.cd_gender, 
    C.demo_count, 
    C.married_count,
    D.d_year,
    D.d_month_seq,
    D.total_dates,
    S.ws_item_sk,
    S.sales_count,
    S.total_sales,
    S.total_discount
FROM 
    AddressCounts A
JOIN 
    CustomerDemographics C ON A.address_count > 100
JOIN 
    DateDetails D ON D.total_dates > 50
JOIN 
    SalesSummary S ON S.sales_count > 200
ORDER BY 
    A.address_count DESC, C.demo_count ASC;

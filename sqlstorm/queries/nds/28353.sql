
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(REPLACE(REPLACE(ca_street_name, 'St.', ''), 'Ave.', '')) AS cleaned_street_name,
        CASE 
            WHEN LENGTH(ca_street_number) > 0 THEN ca_street_number
            ELSE 'N/A' 
        END AS street_number
    FROM 
        customer_address
),
GenderCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2020-01-01' AND '2023-12-31'
    GROUP BY 
        d_year
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.cleaned_street_name,
    ca.street_number,
    gc.cd_gender,
    gc.gender_count,
    di.d_year,
    di.total_dates,
    ss.total_sales,
    ss.total_discounts
FROM 
    AddressParts ca
JOIN 
    GenderCounts gc ON gc.gender_count > 100
JOIN 
    DateInfo di ON di.total_dates > 0
LEFT JOIN 
    SalesSummary ss ON ss.ws_bill_customer_sk = ca.ca_address_sk
WHERE 
    ca.cleaned_street_name IS NOT NULL
ORDER BY 
    ss.total_sales DESC
LIMIT 100;

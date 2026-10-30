
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_city, ca_state, ca_zip, ca_country
), 
CustomerDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
), 
SalesSummary AS (
    SELECT 
        d.d_year,
        sm.sm_type,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        d.d_year, sm.sm_type
)
SELECT 
    ad.full_address,
    ad.ca_country,
    ad.address_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    ss.d_year,
    ss.sm_type,
    ss.total_sales
FROM 
    AddressDetails ad
CROSS JOIN 
    CustomerDetails cd
CROSS JOIN 
    SalesSummary ss
WHERE 
    ad.address_count > 1 AND 
    cd.customer_count > 10 AND 
    ss.total_sales > 1000
ORDER BY 
    ad.full_address, cd.cd_gender, ss.d_year;

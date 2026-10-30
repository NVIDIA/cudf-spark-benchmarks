
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_count,
    ci.total_dependents,
    ci.employed_dependents,
    ci.college_dependents,
    ss.d_year,
    ss.total_sales,
    ss.total_quantity,
    ss.total_discount
FROM 
    AddressInfo ai
JOIN 
    CustomerInfo ci ON ai.address_count > 50
JOIN 
    SalesSummary ss ON ss.total_sales > 100000
ORDER BY 
    ai.ca_city, ci.cd_gender, ss.d_year DESC;

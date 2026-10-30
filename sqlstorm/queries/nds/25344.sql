
WITH AddressDetails AS (
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
CustomerOverview AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesDetails AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
FinalBenchmark AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.full_address,
        a.address_count,
        c.cd_gender,
        c.cd_marital_status,
        c.total_customers,
        c.avg_purchase_estimate,
        c.total_dependents,
        s.d_year,
        s.total_sales
    FROM 
        AddressDetails a
    JOIN 
        CustomerOverview c ON a.ca_city = 'Los Angeles' AND a.ca_state = 'CA'
    JOIN 
        SalesDetails s ON s.d_year = 2023
)
SELECT 
    CONCAT('City: ', ca_city, ', State: ', ca_state) AS location,
    full_address,
    address_count,
    cd_gender,
    cd_marital_status,
    total_customers,
    avg_purchase_estimate,
    total_dependents,
    d_year,
    total_sales
FROM 
    FinalBenchmark
ORDER BY 
    total_sales DESC, address_count DESC;

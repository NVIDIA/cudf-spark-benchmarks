
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_sales,
        STRING_AGG(DISTINCT CAST(ws_order_number AS STRING), ', ') AS order_numbers
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    A.ca_state, 
    A.address_count, 
    A.cities, 
    C.cd_gender, 
    C.customer_count, 
    C.customer_names, 
    S.ws_ship_date_sk, 
    S.total_sales, 
    S.order_numbers
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON A.ca_state = 'CA' 
JOIN 
    SalesStats S ON S.ws_ship_date_sk IS NOT NULL
ORDER BY 
    A.address_count DESC, 
    C.customer_count DESC;

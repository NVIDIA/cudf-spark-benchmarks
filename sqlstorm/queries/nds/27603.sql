
WITH CustomerAddressCTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDemographicsCTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        LOWER(cd_credit_rating) AS credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
DateDimensionCTE AS (
    SELECT 
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_day_name
    FROM 
        date_dim 
    WHERE 
        d_year >= 2020
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue,
        dd.d_year,
        dd.d_month_seq,
        dd.d_day_name
    FROM 
        web_sales ws
    JOIN 
        DateDimensionCTE dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_item_sk, dd.d_year, dd.d_month_seq, dd.d_day_name
)
SELECT 
    ca.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.total_sold) AS total_units_sold,
    SUM(sd.total_revenue) AS total_revenue_generated
FROM 
    CustomerAddressCTE ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    CustomerDemographicsCTE cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    SalesDetails sd ON c.c_customer_sk = sd.ws_item_sk
GROUP BY 
    ca.full_address,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY 
    total_revenue_generated DESC
LIMIT 100;

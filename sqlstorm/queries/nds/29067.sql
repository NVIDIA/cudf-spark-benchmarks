
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ap.full_address,
        ap.ca_city,
        ap.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ap ON c.c_current_addr_sk = ap.ca_address_sk
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        d.d_date_id,
        d.d_year,
        d.d_month_seq
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(ws.ws_order_number) AS total_orders,
        dr.d_year
    FROM 
        web_sales ws
    JOIN 
        DateRange dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk, dr.d_year
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    sd.total_sales_amount,
    sd.total_orders,
    cd.full_address,
    cd.ca_city,
    cd.ca_state
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_purchase_estimate > 1000
ORDER BY 
    sd.total_sales_amount DESC, cd.full_name;

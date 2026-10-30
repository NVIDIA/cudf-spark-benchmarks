
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country 
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date_sk, 
        d_date, 
        d_day_name, 
        d_month_seq, 
        d_year
    FROM 
        date_dim
    WHERE 
        d_year BETWEEN 2020 AND 2023
),
SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_ext_sales_price, 
        ws.ws_ship_date_sk, 
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        d.d_day_name,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        DateDetails d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_ext_sales_price) AS total_sales_amount,
    SUM(sd.ws_net_profit) AS total_net_profit,
    sd.d_day_name,
    sd.d_year
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk
JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY 
    ad.full_address, 
    cd.full_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    sd.d_day_name, 
    sd.d_year
ORDER BY 
    total_net_profit DESC;

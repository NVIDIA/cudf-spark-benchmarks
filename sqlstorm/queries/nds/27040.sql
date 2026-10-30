
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate > 1000
),
DateDetails AS (
    SELECT 
        d.d_date_id,
        d.d_year,
        d.d_month_seq
    FROM 
        date_dim d
    WHERE 
        d.d_year >= 1998
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ws.ws_item_sk
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_close_date_sk IS NULL
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    dd.d_date_id,
    dd.d_year,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_sales_price) AS total_sales
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_zip = CAST(cd.c_customer_id AS STRING)
JOIN 
    DateDetails dd ON dd.d_month_seq = MONTH(CAST('2002-10-01 12:34:56' AS TIMESTAMP))
JOIN 
    SalesData sd ON sd.ws_sales_price IS NOT NULL
GROUP BY 
    ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip, ad.ca_country, 
    cd.full_name, cd.cd_gender, cd.cd_marital_status, dd.d_date_id, dd.d_year
ORDER BY 
    total_sales DESC;

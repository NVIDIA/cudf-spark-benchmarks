
WITH AddressData AS (
    SELECT 
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
), 
CustomerData AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        c_customer_sk,
        c_current_addr_sk
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateData AS (
    SELECT 
        d_date,
        d_month_seq,
        d_year,
        d_day_name,
        d_date_sk
    FROM 
        date_dim
    WHERE 
        d_holiday = 'Y'
),
WebSalesData AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ws_sold_date_sk,
        ws_bill_customer_sk
    FROM 
        web_sales
)
SELECT 
    cd.customer_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    dd.d_date,
    dd.d_day_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    WebSalesData ws
JOIN 
    CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
JOIN 
    AddressData ad ON cd.c_current_addr_sk = ad.ca_address_sk
JOIN 
    DateData dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 1000
GROUP BY 
    cd.customer_name, 
    ad.full_address, 
    ad.ca_city, 
    ad.ca_state, 
    ad.ca_country, 
    dd.d_date, 
    dd.d_day_name
ORDER BY 
    total_net_paid DESC, 
    cd.customer_name;


WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CASE 
            WHEN LENGTH(ca_zip) = 5 THEN CONCAT(SUBSTRING(ca_zip FROM 1 FOR 5), '-', SUBSTRING(ca_zip FROM 6 FOR 4))
            ELSE ca_zip
        END AS formatted_zip,
        ca_city,
        ca_state,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        c_customer_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date,
        d_day_name,
        d_month_seq,
        d_year,
        d_date_sk
    FROM 
        date_dim
),
SalesData AS (
    SELECT 
        ws_sales_price,
        ws_quantity,
        CONCAT('Order:', ws_order_number, ' | Date:', d.d_date, ' | ', a.full_address) AS order_details,
        c.full_name AS customer_name,
        c.cd_gender AS customer_gender,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        DateDetails d ON ws_sold_date_sk = d.d_date_sk
    JOIN 
        CustomerDetails c ON ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        AddressInfo a ON ws_bill_addr_sk = a.ca_address_sk
)
SELECT 
    COUNT(*) AS total_orders,
    SUM(ws_sales_price * ws_quantity) AS total_revenue,
    customer_gender,
    EXTRACT(YEAR FROM d_date) AS sale_year
FROM 
    SalesData
GROUP BY 
    customer_gender, sale_year
ORDER BY 
    sale_year, customer_gender;


WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        CONCAT(SUBSTR(ca_zip, 1, 5), '-', SUBSTR(ca_zip, 6, 4)) AS formatted_zip
    FROM customer_address
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), ShipDetails AS (
    SELECT 
        ws.ws_order_number,
        sm.sm_carrier,
        wd.w_warehouse_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wd ON ws.ws_warehouse_sk = wd.w_warehouse_sk
), Benchmark AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.formatted_zip,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.sm_carrier,
        SUM(sd.ws_sales_price) AS total_sales,
        COUNT(sd.ws_order_number) AS order_count
    FROM AddressDetails ad
    JOIN CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk 
    JOIN ShipDetails sd ON sd.ws_bill_customer_sk = cd.c_customer_sk 
    GROUP BY 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.formatted_zip,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.sm_carrier
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM Benchmark
ORDER BY total_sales DESC;

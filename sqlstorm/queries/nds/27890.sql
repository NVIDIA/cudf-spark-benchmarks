
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnData AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(rd.total_returned, 0) AS total_returned,
    COALESCE(rd.return_count, 0) AS return_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM CustomerDetails cd
JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN ReturnData rd ON cd.c_customer_sk = rd.wr_returning_customer_sk
WHERE ad.ca_state = 'CA' 
AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
ORDER BY total_sales DESC
LIMIT 100;

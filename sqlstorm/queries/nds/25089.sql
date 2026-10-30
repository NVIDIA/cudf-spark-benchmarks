
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM
        customer_address
),
CustomerFullNames AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cfn.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    sd.total_quantity,
    sd.order_count,
    sd.total_net_profit,
    LEFT(ad.full_address, 30) AS truncated_address,
    UPPER(ad.ca_city) AS upper_city
FROM
    CustomerFullNames cfn
JOIN
    SalesData sd ON cfn.c_customer_sk = sd.ws_bill_customer_sk
JOIN
    AddressDetails ad ON cfn.c_customer_sk = ad.ca_address_sk
WHERE
    sd.total_quantity > 10
ORDER BY
    sd.total_net_profit DESC,
    cfn.full_name ASC
LIMIT 100;

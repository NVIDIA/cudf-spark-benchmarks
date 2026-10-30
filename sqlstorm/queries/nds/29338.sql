
WITH AddressDetails AS (
    SELECT
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        COUNT(*) AS address_count,
        ca_address_sk
    FROM
        customer_address
    GROUP BY
        ca_city, ca_state, ca_street_number, ca_street_name, ca_street_type, ca_zip, ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_addr_sk,
        SUM(ws_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_addr_sk
),
JoinedData AS (
    SELECT
        ad.ca_city,
        ad.ca_state,
        ad.full_address,
        ad.ca_zip,
        COALESCE(sd.total_sales, 0) AS total_sales,
        ad.address_count
    FROM
        AddressDetails ad
    LEFT JOIN
        SalesData sd ON ad.ca_address_sk = sd.ws_bill_addr_sk
)
SELECT
    ca_city AS city,
    ca_state AS state,
    full_address,
    ca_zip AS zip,
    total_sales,
    address_count,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM
    JoinedData
WHERE
    total_sales > 0
ORDER BY
    total_sales DESC
LIMIT 100;

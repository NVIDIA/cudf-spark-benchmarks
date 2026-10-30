
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM
        customer
        JOIN customer_demographics ON c_customer_sk = cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
ReturnData AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return,
        COUNT(wr_order_number) AS return_count
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
)
SELECT
    cust.full_name,
    cust.cd_gender,
    cust.cd_marital_status,
    cust.cd_education_status,
    addr.full_address,
    addr.ca_city,
    addr.ca_state,
    addr.ca_zip,
    COALESCE(sales.total_sales, 0) AS total_sales,
    COALESCE(sales.order_count, 0) AS order_count,
    COALESCE(ret.total_return, 0) AS total_return,
    COALESCE(ret.return_count, 0) AS return_count,
    (COALESCE(sales.total_sales, 0) - COALESCE(ret.total_return, 0)) AS net_sales
FROM
    CustomerDetails cust
    JOIN AddressDetails addr ON cust.c_customer_sk = addr.ca_address_sk
    LEFT JOIN SalesData sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
    LEFT JOIN ReturnData ret ON cust.c_customer_sk = ret.wr_returning_customer_sk
WHERE
    addr.ca_state = 'CA'
ORDER BY
    net_sales DESC
LIMIT 100;

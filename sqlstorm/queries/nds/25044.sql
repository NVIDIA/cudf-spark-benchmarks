
WITH CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.full_name,
        cd.ca_city,
        cd.ca_state
    FROM
        web_sales ws
    JOIN
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE
        ws.ws_sales_price > 100.00
),
AggregatedSales AS (
    SELECT
        full_name,
        ca_city,
        ca_state,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        SalesData
    GROUP BY
        full_name, ca_city, ca_state
)
SELECT
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM
    AggregatedSales
ORDER BY
    total_sales DESC, order_count DESC;

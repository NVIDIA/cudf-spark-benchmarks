
WITH CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
HighValueItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    WHERE
        sd.total_sales > (SELECT AVG(total_sales) FROM SalesData)
),
FinalReport AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.full_address,
        hvi.total_quantity,
        hvi.total_sales
    FROM
        CustomerInfo ci
    JOIN
        HighValueItems hvi ON ci.c_customer_sk = hvi.ws_item_sk
)
SELECT
    *,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM
    FinalReport
ORDER BY
    total_sales DESC
LIMIT 50;

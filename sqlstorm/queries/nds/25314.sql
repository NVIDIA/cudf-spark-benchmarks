
WITH AddressDetails AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM
        customer_address ca
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_sold_date_sk
),
DetailedSales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.total_sales,
        sd.total_orders,
        dd.d_date AS sale_date
    FROM
        SalesData sd
    JOIN date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
)
SELECT
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ds.sale_date,
    ds.total_sales,
    ds.total_orders
FROM
    AddressDetails ad
JOIN CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk
JOIN DetailedSales ds ON ds.total_orders > 0
WHERE
    ad.ca_state = 'CA' AND
    cd.cd_gender = 'F' AND
    cd.cd_purchase_estimate > 1000
ORDER BY
    ds.sale_date DESC, ds.total_sales DESC
LIMIT 100;

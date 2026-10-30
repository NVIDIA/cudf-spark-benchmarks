
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
DemoAndAddress AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.FullAddress,
        a.ca_city,
        a.ca_state
    FROM
        customer c
    JOIN
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT
        d.c_customer_sk,
        d.c_first_name,
        d.c_last_name,
        d.ca_city,
        d.ca_state,
        sd.TotalSales,
        sd.OrderCount,
        RANK() OVER (ORDER BY sd.TotalSales DESC) AS SalesRank
    FROM
        DemoAndAddress d
    JOIN
        SalesData sd ON d.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    t.c_first_name,
    t.c_last_name,
    t.ca_city,
    t.ca_state,
    t.TotalSales,
    t.OrderCount
FROM
    TopCustomers t
WHERE
    t.SalesRank <= 10
ORDER BY
    t.TotalSales DESC;

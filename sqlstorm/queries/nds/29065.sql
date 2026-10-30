
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) AS full_address,
        TRIM(ca_city) || ', ' || TRIM(ca_state) || ' ' || TRIM(ca_zip) AS location,
        ca_country
    FROM
        customer_address
),
SalesData AS (
    SELECT
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        ws_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        MAX(d.d_date) AS last_order_date
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_sk
),
FinalBenchmark AS (
    SELECT
        a.full_address,
        a.location,
        a.ca_country,
        c.total_orders AS customer_orders,
        c.total_profit AS customer_profit,
        s.total_orders AS sales_orders,
        s.total_sales,
        s.total_profit AS sales_profit
    FROM
        AddressDetails a
    LEFT JOIN
        CustomerStats c ON a.ca_address_sk = c.c_customer_sk
    LEFT JOIN
        SalesData s ON a.ca_address_sk = s.ws_item_sk
)
SELECT 
    full_address,
    location,
    ca_country,
    customer_orders,
    customer_profit,
    sales_orders,
    total_sales,
    sales_profit
FROM 
    FinalBenchmark
WHERE 
    customer_orders > 0 OR sales_orders > 0
ORDER BY 
    sales_profit DESC
LIMIT 100;

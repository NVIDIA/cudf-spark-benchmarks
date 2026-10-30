
WITH FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
      AND ca.ca_city LIKE '%ville%'
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN FilteredCustomers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    fc.full_name,
    fc.ca_city,
    fc.ca_state,
    fc.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.avg_sales_price, 0) AS avg_sales_price,
    sd.sales_rank
FROM FilteredCustomers fc
LEFT JOIN SalesData sd ON fc.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY total_sales DESC, fc.full_name;

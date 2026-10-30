
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_gender = 'F' AND cd_marital_status = 'M'
    GROUP BY ws_bill_customer_sk
),
AddressData AS (
    SELECT 
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address
    JOIN customer ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_country
),
CustomerSummary AS (
    SELECT 
        s.ws_bill_customer_sk,
        s.total_sales,
        s.total_discount,
        s.total_orders,
        a.customer_count
    FROM SalesData s
    LEFT JOIN AddressData a ON a.customer_count > 0
)
SELECT 
    cs.ws_bill_customer_sk,
    cs.total_sales,
    cs.total_discount,
    cs.total_orders,
    COALESCE(cs.customer_count, 0) AS total_customers
FROM CustomerSummary cs
ORDER BY cs.total_sales DESC
LIMIT 10;

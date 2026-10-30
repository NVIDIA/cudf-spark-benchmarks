
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_country) AS country_lower,
        LENGTH(ca_zip) AS zip_length
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
DetailedReport AS (
    SELECT 
        c.c_customer_sk,
        c.full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.country_lower,
        s.total_orders,
        s.total_sales,
        s.net_profit,
        CASE 
            WHEN s.total_orders IS NOT NULL THEN 
                CASE 
                    WHEN s.net_profit > 1000 THEN 'High Value'
                    WHEN s.net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
                    ELSE 'Low Value'
                END
            ELSE 'No Orders'
        END AS customer_value_segment
    FROM CustomerDetails c
    LEFT JOIN AddressDetails a ON a.ca_address_sk = c.c_customer_sk
    LEFT JOIN SalesSummary s ON s.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    customer_value_segment,
    COUNT(*) AS number_of_customers,
    AVG(total_sales) AS avg_sales,
    SUM(net_profit) AS total_net_profit
FROM DetailedReport
GROUP BY customer_value_segment
ORDER BY total_net_profit DESC;

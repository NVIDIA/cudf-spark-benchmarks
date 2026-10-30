WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cs.total_sales,
        cs.order_count
    FROM customer c
    JOIN sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer_address ca
    WHERE ca.ca_state IS NOT NULL
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS latest_purchase_date,
        COALESCE(cc.cc_name, 'Online') AS channel
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON c.c_first_shipto_date_sk = cc.cc_call_center_sk
    WHERE c.c_birth_year > 1980
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    cd.latest_purchase_date,
    cd.channel
FROM high_value_customers hvc
JOIN customer_addresses ca ON hvc.c_customer_sk = ca.ca_address_sk
JOIN customer_details cd ON hvc.c_customer_sk = cd.c_customer_sk
WHERE hvc.order_count > 5
ORDER BY hvc.total_sales DESC
LIMIT 100;
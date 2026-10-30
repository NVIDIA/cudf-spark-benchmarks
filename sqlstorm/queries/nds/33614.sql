
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),

top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.total_sales,
        ss.total_orders
    FROM customer AS cs
    JOIN customer_demographics AS cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_summary AS ss ON cs.c_customer_sk = ss.customer_sk
    WHERE ss.sales_rank <= 10
),

customer_addresses AS (
    SELECT 
        cs.c_customer_id,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state
    FROM customer AS cs
    LEFT JOIN customer_address AS ca ON cs.c_current_addr_sk = ca.ca_address_sk
)

SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(ca.ca_street_number || ' ' || ca.ca_street_name, 'N/A') AS address,
    COALESCE(ca.ca_city, 'N/A') AS city,
    COALESCE(ca.ca_state, 'N/A') AS state,
    tc.total_sales,
    tc.total_orders
FROM top_customers AS tc
FULL OUTER JOIN customer_addresses AS ca ON tc.c_customer_id = ca.c_customer_id
WHERE tc.total_sales IS NOT NULL OR ca.ca_street_number IS NOT NULL
ORDER BY tc.total_sales DESC NULLS LAST;


WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_estimate_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate > (
        SELECT AVG(cd2.cd_purchase_estimate) 
        FROM customer_demographics cd2
        WHERE cd2.cd_gender = cd.cd_gender
    )
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_purchase_estimate,
        hs.ca_city,
        ss.total_sales,
        ss.total_orders
    FROM customer_info ci
    LEFT JOIN high_estimate_customers hs ON ci.c_customer_sk = hs.c_customer_sk
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE (ss.total_sales IS NOT NULL AND ss.total_sales > 5000)
       OR (ci.purchase_rank <= 5 AND ci.cd_gender = 'F')
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.ca_city,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.total_orders, 0) AS total_orders
FROM final_report f
ORDER BY f.cd_gender, f.total_sales DESC;

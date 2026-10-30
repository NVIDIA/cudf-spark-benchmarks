
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(LEFT(ca.ca_street_type, 5), ' ', ca.ca_street_name) AS street_info,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
),
DetailedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)

SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.street_info,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    p.p_promo_name,
    p.order_count,
    p.total_sales,
    ds.total_quantity,
    ds.total_profit,
    ds.unique_orders
FROM CustomerInfo ci
LEFT JOIN Promotions p ON ci.c_customer_sk = p.order_count
LEFT JOIN DetailedSales ds ON ci.c_customer_sk = ds.ws_item_sk
WHERE ci.cd_gender = 'F'
AND ci.cd_marital_status = 'M'
ORDER BY total_sales DESC, unique_orders DESC
LIMIT 100;

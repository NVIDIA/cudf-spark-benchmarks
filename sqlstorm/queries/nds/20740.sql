
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rank_customer
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 0
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        SUM(CASE WHEN rs.rank_sales = 1 THEN rs.ws_sales_price ELSE 0 END) AS max_web_sale,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.max_web_sale,
    s.order_count,
    COALESCE(i.ib_income_band_sk, 0) AS income_band
FROM 
    sales_summary s
LEFT JOIN 
    household_demographics hd ON hd.hd_demo_sk = s.c_customer_sk
LEFT JOIN 
    income_band i ON hd.hd_income_band_sk = i.ib_income_band_sk
WHERE 
    (s.order_count > 5 OR s.max_web_sale > 100)
    AND (s.cd_gender = 'F' OR s.cd_gender IS NULL)
ORDER BY 
    s.max_web_sale DESC, s.order_count ASC
LIMIT 50;

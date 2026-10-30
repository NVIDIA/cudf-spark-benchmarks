
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, ca.ca_city, ca.ca_state
),
ranked_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.ca_city,
        ci.ca_state,
        ci.total_spent,
        RANK() OVER (ORDER BY ci.total_spent DESC) AS customer_rank
    FROM 
        customer_info ci
)
SELECT 
    rc.cd_gender,
    rc.ca_state,
    COUNT(*) AS customer_count,
    AVG(rc.total_spent) AS average_spent,
    MAX(ss.total_sales) AS highest_sales
FROM 
    ranked_customers rc
JOIN 
    sales_summary ss ON ss.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
WHERE 
    rc.customer_rank <= 100
GROUP BY 
    rc.cd_gender, rc.ca_state
HAVING 
    AVG(rc.total_spent) > (SELECT AVG(total_spent) FROM ranked_customers) 
ORDER BY 
    rc.cd_gender, rc.ca_state;

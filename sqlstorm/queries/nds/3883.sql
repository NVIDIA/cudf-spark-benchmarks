
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price * ws_quantity) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, ca.ca_city, ca.ca_state
),
high_spenders AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent > 500 THEN 'High spender'
            ELSE 'Regular spender'
        END AS spending_category
    FROM 
        customer_data
    WHERE 
        total_orders > 5
),
final_selection AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.spending_category,
        COALESCE(SUM(r.ws_sales_price * r.ws_quantity), 0) AS total_returns
    FROM 
        high_spenders cs
    LEFT JOIN 
        store_returns sr ON cs.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        ranked_sales r ON r.ws_item_sk = sr.sr_item_sk 
    GROUP BY 
        cs.c_customer_sk, cs.total_orders, cs.total_spent, cs.spending_category
)
SELECT 
    f.c_customer_sk,
    f.total_orders,
    f.total_spent,
    f.spending_category,
    f.total_returns,
    CASE 
        WHEN f.total_returns > 100 THEN 'Frequent returns'
        ELSE 'Infrequent returns'
    END AS return_frequency
FROM 
    final_selection f
WHERE 
    f.total_spent IS NOT NULL
ORDER BY 
    f.total_spent DESC, f.c_customer_sk
LIMIT 50;


WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        hd.hd_buy_potential,
        c.c_email_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_customer_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND hd.hd_buy_potential IN ('High', 'Very High')
),
sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sales_price > (
            SELECT AVG(ws2.ws_sales_price) 
            FROM web_sales AS ws2
        )
),
final_results AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.ca_city,
        ci.ca_state,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_spent,
        COUNT(sd.ws_item_sk) AS items_purchased
    FROM 
        customer_info AS ci
    LEFT JOIN 
        sales_data AS sd ON sd.ws_ship_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim AS d 
            WHERE 
                d.d_year = (SELECT MAX(d_year) FROM date_dim)
        )
    GROUP BY 
        ci.full_name, ci.cd_gender, ci.ca_city, ci.ca_state
)
SELECT 
    full_name,
    cd_gender,
    ca_city,
    ca_state,
    total_spent,
    items_purchased,
    CASE 
        WHEN total_spent > 1000 THEN 'VIP'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_segment
FROM 
    final_results
ORDER BY 
    total_spent DESC
LIMIT 100;

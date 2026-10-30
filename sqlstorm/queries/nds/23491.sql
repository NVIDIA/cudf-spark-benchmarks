
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        SUM(ws.ws_net_paid) AS total_paid,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ws.ws_order_number
),
address_info AS (
    SELECT 
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip
),
sales_statistics AS (
    SELECT 
        r.c_customer_id,
        r.total_paid,
        a.ca_city,
        a.ca_state,
        (SELECT COUNT(*) FROM web_sales WHERE ws_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns) AND ws_order_number = r.ws_order_number) AS return_count
    FROM 
        ranked_sales r
    JOIN 
        address_info a ON r.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk IS NOT NULL LIMIT 1)
    WHERE 
        r.rank = 1
)

SELECT 
    s.c_customer_id,
    s.total_paid,
    a.ca_city,
    a.ca_state,
    COALESCE(s.return_count, 0) AS return_count,
    CASE 
        WHEN s.total_paid > 1000 THEN 'High Value Customer'
        WHEN s.total_paid BETWEEN 500 AND 1000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_category
FROM 
    sales_statistics s
JOIN 
    address_info a ON s.ca_city = a.ca_city AND s.ca_state = a.ca_state
WHERE 
    s.total_paid IS NOT NULL
    AND (EXISTS (SELECT 1 FROM store s1 WHERE s1.s_country IS NULL) OR s.return_count > 5)
ORDER BY 
    s.total_paid DESC 
LIMIT 10;

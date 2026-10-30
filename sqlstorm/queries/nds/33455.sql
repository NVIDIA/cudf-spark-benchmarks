
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
top_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > (
            SELECT AVG(i2.i_current_price) FROM item i2
        )
    GROUP BY 
        ws.ws_item_sk
),
final_report AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ts.total_quantity_sold,
        ts.total_sales,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ts.total_sales DESC) AS rank
    FROM 
        top_customers tc
    JOIN 
        customer_addresses ca ON tc.c_customer_sk = ca.customer_count
    JOIN 
        top_sales ts ON tc.total_spent > ts.total_sales
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.ca_city,
    fr.ca_state,
    fr.total_sales
FROM 
    final_report fr
WHERE 
    fr.rank <= 5
ORDER BY 
    fr.ca_state, fr.total_sales DESC;

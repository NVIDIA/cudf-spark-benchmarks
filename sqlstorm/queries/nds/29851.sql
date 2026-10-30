
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        a.ca_state,
        d.d_year AS last_purchase_year,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, d.d_year
), ranked_customers AS (
    SELECT 
        ci.*,
        ROW_NUMBER() OVER (PARTITION BY ci.ca_state ORDER BY ci.total_orders DESC, ci.unique_items_purchased DESC) AS rank
    FROM 
        customer_info ci
)
SELECT 
    rc.c_customer_id,
    rc.full_name,
    rc.ca_city,
    rc.ca_state,
    rc.last_purchase_year,
    rc.total_orders,
    rc.unique_items_purchased
FROM 
    ranked_customers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.ca_state, rc.rank;


WITH  top_categories AS (
    SELECT 
        i_category_id, 
        i_category, 
        COUNT(ws_order_number) AS total_sales
    FROM 
        item 
    JOIN 
        web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY 
        i_category_id, i_category
    HAVING 
        COUNT(ws_order_number) > 0
),
sales_by_customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND 
        c.c_birth_month IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        customer_address ca
    LEFT JOIN 
        store_returns sr ON ca.ca_address_sk = sr.sr_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
    ORDER BY 
        return_count DESC
    LIMIT 10
)
SELECT 
    tc.i_category_id,
    tc.i_category,
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_profit,
    tb.ca_city,
    tb.return_count,
    CASE WHEN s.orders_count > 5 THEN 'Frequent' ELSE 'Infrequent' END AS customer_type
FROM 
    top_categories tc
JOIN 
    sales_by_customer s ON s.total_profit > 5000
JOIN 
    top_addresses tb ON s.c_customer_sk IN (
        SELECT sr.sr_customer_sk
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
    )
WHERE 
    tc.total_sales > 1000
ORDER BY 
    total_profit DESC, 
    return_count DESC;


WITH combined_sales AS (
    SELECT
        ws.ws_order_number AS order_num,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS bill_customer,
        ws.ws_ship_customer_sk AS ship_customer,
        ws.ws_sales_price AS sales_price,
        ws.ws_net_profit AS net_profit,

        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        ca.ca_city AS billing_city,
        ca.ca_state AS billing_state,
        COALESCE(LOWER(REPLACE(c.c_email_address, '@', ' at ')), 'unknown') AS email_replacement
    FROM
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_items AS (
    SELECT 
        item_sk,
        SUM(net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(net_profit) DESC) AS item_rank
    FROM 
        combined_sales 
    GROUP BY 
        item_sk
)
SELECT 
    ci.item_sk,
    ti.total_profit,
    ti.item_rank,
    ci.customer_full_name,
    ci.billing_city,
    ci.billing_state,
    ci.email_replacement
FROM 
    combined_sales ci
JOIN 
    top_items ti ON ci.item_sk = ti.item_sk
WHERE 
    ti.item_rank <= 10
ORDER BY 
    ti.total_profit DESC, 
    ci.customer_full_name ASC;

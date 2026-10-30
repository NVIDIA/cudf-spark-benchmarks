WITH  sales_summary AS (
    SELECT
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        SUM(web_sales.ws_net_profit) AS total_net_profit,
        COUNT(web_sales.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY customer.c_customer_sk ORDER BY SUM(web_sales.ws_net_profit) DESC) AS rank
    FROM
        customer
    LEFT JOIN
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    WHERE
        web_sales.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001) - 30 
    GROUP BY
        customer.c_customer_sk, customer.c_first_name, customer.c_last_name
),
top_customers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_net_profit,
        total_orders
    FROM
        sales_summary
    WHERE
        rank <= 10
),
excluded_customers AS (
    SELECT
        c_customer_sk
    FROM
        top_customers
    WHERE
        total_net_profit < (SELECT AVG(total_net_profit) FROM sales_summary)
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT tc.c_customer_sk) AS high_value_customers,
    SUM(tc.total_net_profit) AS total_net_profit,
    AVG(tc.total_orders) AS avg_orders
FROM
    customer_address ca
INNER JOIN
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
INNER JOIN
    top_customers tc ON c.c_customer_sk = tc.c_customer_sk
LEFT JOIN
    excluded_customers ec ON c.c_customer_sk = ec.c_customer_sk
WHERE
    ec.c_customer_sk IS NULL
GROUP BY
    ca.ca_city, ca.ca_state
ORDER BY
    total_net_profit DESC
LIMIT 5;
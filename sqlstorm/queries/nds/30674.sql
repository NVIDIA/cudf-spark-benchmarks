
WITH  sales_totals AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS order_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_addresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
dated_sales AS (
    SELECT 
        ds.d_year,
        SUM(ws.ws_net_profit) AS yearly_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    GROUP BY 
        ds.d_year
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        st.total_profit,
        st.total_orders,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        sales_totals st
    JOIN 
        customer_addresses ca ON st.ws_bill_customer_sk = ca.c_customer_sk
    JOIN 
        customer c ON st.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        st.total_profit > (SELECT AVG(total_profit) FROM sales_totals)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_profit,
    hvc.total_orders,
    hvc.ca_city,
    hvc.ca_state,
    hvc.ca_country,
    ds.d_year,
    ds.yearly_profit,
    ds.total_sales
FROM 
    high_value_customers hvc
LEFT JOIN 
    dated_sales ds ON hvc.c_customer_sk IN (
        SELECT ws_bill_customer_sk
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    )
WHERE 
    hvc.total_orders > (SELECT AVG(total_orders) FROM sales_totals)
ORDER BY 
    hvc.total_profit DESC, 
    hvc.c_last_name ASC;

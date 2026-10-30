
SELECT 
    d.d_year AS sales_year,
    d.d_month_seq AS sales_month,
    ca.ca_state AS state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
FROM 
    web_sales ws
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year >= 2020
    AND (d.d_month_seq BETWEEN 1 AND 12)
GROUP BY 
    d.d_year, d.d_month_seq, ca.ca_state
ORDER BY 
    sales_year DESC, sales_month ASC, total_net_profit DESC
LIMIT 100;

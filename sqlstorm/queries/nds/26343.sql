
WITH CombinedSales AS (
    SELECT 
        ws.ws_order_number AS order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS net_profit,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        ca.ca_city AS city,
        ca.ca_state AS state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        order_number, customer_name, ca.ca_city, ca.ca_state
),
AggregatedSales AS (
    SELECT 
        city, 
        state,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        SUM(total_discount) AS total_discount,
        SUM(net_profit) AS total_net_profit
    FROM 
        CombinedSales
    GROUP BY 
        city, state
)
SELECT 
    city,
    state,
    total_quantity,
    total_sales,
    total_discount,
    total_net_profit,
    total_sales - total_discount AS net_revenue,
    CASE 
        WHEN total_quantity > 1000 THEN 'High Volume'
        WHEN total_quantity >= 500 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    AggregatedSales
WHERE 
    total_sales > 1000
ORDER BY 
    total_net_profit DESC;

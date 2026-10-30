
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_month_seq,
        d.d_year,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_payment,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedStats AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ss.total_orders,
        ss.total_profit,
        ss.avg_payment,
        ss.total_items_sold
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesStats ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_profit, 0.00) AS total_profit,
    COALESCE(avg_payment, 0.00) AS avg_payment,
    COALESCE(total_items_sold, 0) AS total_items_sold
FROM 
    CombinedStats
WHERE 
    (total_orders > 10 OR total_profit > 1000)
ORDER BY 
    total_profit DESC, full_name;

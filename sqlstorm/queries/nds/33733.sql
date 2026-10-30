
WITH  sales_data AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(*) AS total_transactions,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ss_ticket_number) AS transactions_count,
        SUM(ss_net_paid) AS total_spent
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c_customer_sk
    HAVING 
        SUM(ss_net_paid) > 1000
),
ship_mode_stats AS (
    SELECT 
        sm.sm_carrier,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_carrier
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sd.total_sales) AS total_item_sales,
    HVC.transactions_count AS c_transactions_count,
    HVC.total_spent,
    SMS.order_count,
    SMS.avg_profit
FROM 
    sales_data sd
JOIN 
    item i ON sd.ss_item_sk = i.i_item_sk
JOIN 
    customer_address ca ON i.i_item_id = ca.ca_address_id
LEFT JOIN 
    high_value_customers HVC ON sd.ss_item_sk = HVC.c_customer_sk
LEFT JOIN 
    ship_mode_stats SMS ON sd.ss_item_sk = SMS.order_count
GROUP BY 
    ca.ca_city, ca.ca_state, HVC.transactions_count, HVC.total_spent, SMS.order_count, SMS.avg_profit
HAVING 
    SUM(sd.total_sales) > 50000
ORDER BY 
    total_item_sales DESC;

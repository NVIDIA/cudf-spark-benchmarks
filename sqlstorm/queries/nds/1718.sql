
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 60
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_spent_per_order
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_performance AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        AVG(ws.ws_net_profit) AS avg_order_value
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
    GROUP BY 
        ca.ca_state
)
SELECT 
    'Web Sales' AS sales_type,
    'Total Sales' AS metric,
    SUM(total_sales) AS value
FROM 
    sales_performance
UNION ALL
SELECT 
    'Web Sales',
    'Total Orders',
    SUM(total_orders)
FROM 
    sales_performance
UNION ALL
SELECT 
    'Catalog Sales',
    'Total Orders',
    SUM(catalog_orders)
FROM 
    (SELECT 
        cs.cs_bill_customer_sk,
        COUNT(cs.cs_order_number) AS catalog_orders
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_bill_customer_sk) AS catalog_summary
UNION ALL
SELECT 
    'Returns',
    'Total Returns',
    SUM(total_returns)
FROM 
    sales_performance
UNION ALL
SELECT 
    'Customer Stats',
    'Average Total Spent',
    AVG(total_spent) AS value
FROM 
    customer_stats
WHERE 
    total_orders > 5
ORDER BY 
    value DESC;

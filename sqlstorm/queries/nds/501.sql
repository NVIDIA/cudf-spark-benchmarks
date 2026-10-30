
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_quantity > 0
),

AggregateSales AS (
    SELECT 
        rs.ws_bill_customer_sk, 
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(rs.ws_item_sk) AS total_items,
        AVG(rs.ws_quantity) AS avg_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_bill_customer_sk
)

SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_credit_rating, 
    ag.total_net_profit, 
    ag.total_items, 
    ag.avg_quantity, 
    ca.ca_city, 
    ca.ca_state 
FROM 
    AggregateSales ag
JOIN 
    customer c ON c.c_customer_sk = ag.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND ag.total_net_profit > 1000

UNION ALL

SELECT 
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS cd_credit_rating,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(ws_item_sk) AS total_items,
    AVG(ws_quantity) AS avg_quantity,
    NULL AS ca_city,
    NULL AS ca_state
FROM 
    web_sales
WHERE 
    ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) 
    AND (SELECT MAX(d_date_sk) FROM date_dim)
    AND ws_net_profit IS NOT NULL
GROUP BY 
    ws_bill_customer_sk
HAVING 
    SUM(ws_net_profit) > 5000
ORDER BY 
    total_net_profit DESC;

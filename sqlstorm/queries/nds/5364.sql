
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_orders,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank_profit
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
yearly_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS annual_profit,
        SUM(ws.ws_quantity) AS annual_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
highest_year AS (
    SELECT 
        d_year, 
        annual_profit, 
        annual_quantity,
        RANK() OVER (ORDER BY annual_profit DESC) AS rank_year
    FROM 
        yearly_sales
)
SELECT 
    tc.rank_profit,
    tc.ca_city,
    tc.cd_gender,
    tc.cd_marital_status,
    hy.d_year,
    hy.annual_profit,
    hy.annual_quantity
FROM 
    top_customers tc
JOIN 
    highest_year hy ON tc.rank_profit <= 10 AND hy.rank_year = 1
ORDER BY 
    tc.total_profit DESC, 
    tc.rank_profit;

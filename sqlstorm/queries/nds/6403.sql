
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit_per_order,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_web_sales) AS state_sales,
        AVG(cs.avg_profit_per_order) AS avg_profit
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
),
TopStates AS (
    SELECT 
        ca_state,
        state_sales,
        avg_profit,
        RANK() OVER (ORDER BY state_sales DESC) AS sales_rank
    FROM 
        SalesByState
)
SELECT 
    ts.ca_state,
    ts.state_sales,
    ts.avg_profit
FROM 
    TopStates ts
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.state_sales DESC;

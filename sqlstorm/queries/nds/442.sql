
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        wr_returning_customer_sk,
        total_returned_quantity,
        total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY total_return_amount DESC) AS rn
    FROM 
        CustomerReturns
)
SELECT 
    c.c_customer_id,
    d.d_date_id,
    c_first_name || ' ' || c_last_name AS full_name,
    coalesce(d.d_current_month, 'N/A') AS current_month,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.wr_returning_customer_sk
WHERE 
    tc.rn = 1
GROUP BY 
    c.c_customer_id, d.d_date_id, c_first_name, c_last_name, cd.cd_marital_status, d.d_current_month
HAVING 
    SUM(ws.ws_net_profit) > 0
ORDER BY 
    total_net_profit DESC
LIMIT 50;

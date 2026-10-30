
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451985 AND 2452047
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_country, 
    SUM(COALESCE(RS.ws_net_profit, 0)) AS total_profit,
    AVG(COALESCE(CD.total_spent, 0)) AS avg_spent_per_cust,
    SUM(COALESCE(R.return_count, 0)) AS total_returns
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales RS ON c.c_customer_sk = RS.ws_sold_date_sk
LEFT JOIN 
    CustomerDetails CD ON c.c_customer_sk = CD.c_customer_sk
LEFT JOIN 
    ReturnStats R ON RS.ws_item_sk = R.sr_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND COALESCE(CD.unique_customers, 0) > 0
GROUP BY 
    ca.ca_country
HAVING 
    SUM(COALESCE(RS.ws_net_profit, 0)) > 10000
ORDER BY 
    total_profit DESC;

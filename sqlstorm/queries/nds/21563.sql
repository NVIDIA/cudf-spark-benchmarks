
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
TopProfitableItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating,
        SUM(CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 1 
            ELSE 0 
        END) AS medium_income_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    t.total_profit, 
    cd.cd_gender, 
    cd.medium_income_count,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    TopProfitableItems t ON c.c_customer_sk = t.ws_item_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND (t.total_profit > 10000 OR t.total_profit IS NULL)
GROUP BY 
    ca.ca_city, ca.ca_state, t.total_profit, cd.cd_gender, cd.medium_income_count
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY 
    t.total_profit DESC NULLS LAST;


WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
)

SELECT 
    ra.ca_city,
    ra.ca_state,
    ra.cd_gender,
    AVG(ra.ws_net_profit) AS avg_net_profit,
    COUNT(ra.ws_order_number) AS order_count
FROM 
    RankedSales ra
WHERE 
    ra.rank <= 10
GROUP BY 
    ra.ca_city, ra.ca_state, ra.cd_gender
ORDER BY 
    avg_net_profit DESC, order_count DESC

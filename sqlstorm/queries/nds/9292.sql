
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        RankedCustomers c
)
SELECT 
    ac.ca_city,
    SUM(tc.total_net_profit) AS city_profit
FROM 
    TopCustomers tc
JOIN 
    customer_address ac ON tc.c_customer_sk = ac.ca_address_sk
WHERE 
    tc.profit_rank <= 10
GROUP BY 
    ac.ca_city
ORDER BY 
    city_profit DESC;

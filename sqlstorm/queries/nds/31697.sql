
WITH  SalesCTE AS (
    SELECT 
        ws_ship_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
MaxSales AS (
    SELECT 
        MAX(total_profit) AS max_profit 
    FROM 
        SalesCTE
),
CustomerRanks AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(total_profit) AS demographic_profit
    FROM 
        SalesCTE 
    JOIN 
        customer ON SalesCTE.ws_ship_customer_sk = customer.c_customer_sk
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE 
        total_profit > (SELECT max_profit FROM MaxSales)
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    demographic_profit,
    AVG(demographic_profit) OVER () AS avg_profit,
    CASE 
        WHEN demographic_profit > (SELECT AVG(demographic_profit) FROM CustomerRanks) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_indicator
FROM 
    CustomerRanks
ORDER BY 
    demographic_profit DESC;


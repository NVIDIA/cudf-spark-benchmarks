
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c_current_cdemo_sk,
        COUNT(DISTINCT c_customer_sk) AS num_customers
    FROM 
        customer
    WHERE 
        c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c_current_cdemo_sk
)
SELECT 
    cd.num_customers,
    sd.total_quantity,
    sd.total_profit,
    cdemo.cd_gender
FROM 
    SalesData sd
JOIN 
    customer_demographics cdemo ON sd.ws_item_sk = cdemo.cd_demo_sk
JOIN 
    CustomerData cd ON cdemo.cd_demo_sk = cd.c_current_cdemo_sk
WHERE 
    sd.total_profit > 10000
ORDER BY 
    cd.num_customers DESC, sd.total_profit DESC
LIMIT 100;

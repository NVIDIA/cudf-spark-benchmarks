
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 0
), 
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_ship_customer_sk
), 
RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cdem.cd_gender, 'U') AS gender,
        cs.total_profit,
        cr.total_returns,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(cdem.cd_gender, 'U') ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cdem ON c.c_current_cdemo_sk = cdem.cd_demo_sk
    LEFT JOIN 
        SalesData cs ON c.c_customer_sk = cs.ws_ship_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    gender,
    AVG(total_profit) AS avg_profit,
    SUM(COALESCE(total_returns, 0)) AS total_returns,
    COUNT(*) AS customer_count
FROM 
    RankedCustomers
WHERE 
    profit_rank <= 10
GROUP BY 
    gender
UNION ALL
SELECT 
    'Total' AS gender,
    AVG(total_profit) AS avg_profit,
    SUM(total_returns) AS total_returns,
    COUNT(*) AS customer_count
FROM 
    RankedCustomers;


WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ship_date_sk DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(rs.rank) AS sale_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        SUM(rs.ws_net_profit) > 1000
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cb.total_returns
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerReturns cb ON cd.cd_demo_sk = cb.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    hpi.total_net_profit,
    COALESCE(cr.total_returns, 0) AS total_customer_returns
FROM 
    customer c
INNER JOIN 
    HighProfitItems hpi ON c.c_customer_sk = hpi.ws_item_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    (cd.cd_gender = 'M' AND cd.cd_marital_status = 'M')
    OR (cd.cd_gender = 'F' AND cd.cd_marital_status IS NULL)
ORDER BY 
    total_customer_returns DESC, total_net_profit DESC;

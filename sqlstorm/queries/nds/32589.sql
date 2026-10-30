
WITH  SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
ProductReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    s.ws_item_sk,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    (COALESCE(cs.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    SalesSummary s
JOIN 
    (SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales
     FROM web_sales 
     GROUP BY ws_item_sk) cs ON cs.ws_item_sk = s.ws_item_sk
LEFT JOIN 
    ProductReturns cr ON cr.sr_item_sk = s.ws_item_sk
JOIN 
    CustomerDemographics cd ON cd.total_sales_count > 0
WHERE 
    s.total_quantity > 100 AND 
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
ORDER BY 
    net_sales DESC
LIMIT 50;

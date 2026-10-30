
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ItemSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_items_sold,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
IncomeDemographics AS (
    SELECT 
        cd_demo_sk,
        ib_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        household_demographics 
    JOIN 
        customer_demographics ON hd_demo_sk = cd_demo_sk
    LEFT JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY 
        cd_demo_sk, ib_income_band_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(isales.total_items_sold, 0) AS total_items_sold,
    COALESCE(isales.total_net_profit, 0) AS total_net_profit,
    id.customer_count AS income_band_customers,
    CASE 
        WHEN cr.total_return_amount > 0 THEN 'Returns Made'
        ELSE 'No Returns' 
    END AS returns_status
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    ItemSales isales ON c.c_customer_sk = isales.customer_sk
LEFT JOIN 
    IncomeDemographics id ON cd.cd_demo_sk = id.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_gender = 'F'
    AND (isales.total_net_profit > 1000 OR cr.total_returns > 5)
ORDER BY 
    total_return_amount DESC, 
    total_items_sold DESC
LIMIT 100;


WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.purchase_rank <= 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year
),
YearlySales AS (
    SELECT 
        sd.ws_item_sk,
        sd.d_year,
        sd.total_quantity,
        sd.total_profit,
        LAG(sd.total_profit) OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.d_year) AS prev_year_profit
    FROM 
        SalesData sd
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns
    FROM 
        TopCustomers c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(SUM(ys.total_profit), 0) AS total_sales_profit,
    cr.total_returns,
    CASE 
        WHEN COUNT(ys.total_profit) > 1 THEN 
            SUM(ys.total_profit) - COALESCE(SUM(ys.prev_year_profit), 0) 
        ELSE 
            SUM(ys.total_profit) 
    END AS profit_growth,
    CASE 
        WHEN cr.total_returns IS NULL THEN 'No Returns'
        ELSE 'Returns Exist'
    END AS return_status
FROM 
    TopCustomers tc
LEFT JOIN 
    YearlySales ys ON tc.c_customer_sk = ys.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON tc.c_customer_sk = cr.c_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, cr.total_returns
HAVING 
    (SUM(ys.total_profit) > 1000 OR cr.total_returns > 0)
ORDER BY 
    total_sales_profit DESC, profit_growth DESC;


WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.sr_customer_sk
),
HighValuedCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.return_count, 0) AS return_count,
        CASE 
            WHEN cr.total_returned > 1000 THEN 'High Return'
            WHEN cr.total_returned BETWEEN 500 AND 1000 THEN 'Medium Return'
            ELSE 'Low Return' 
        END AS return_category
    FROM 
        RankedCustomers AS rc
    LEFT JOIN 
        CustomerReturns AS cr ON rc.c_customer_sk = cr.sr_customer_sk
    WHERE 
        rc.rnk <= 5
),
SalesOverview AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_ship_date_sk
),
DailySales AS (
    SELECT 
        dd.d_date,
        so.total_net_profit,
        RANK() OVER (ORDER BY so.total_net_profit DESC) AS sales_rank
    FROM 
        SalesOverview AS so
    JOIN 
        date_dim AS dd ON so.ws_ship_date_sk = dd.d_date_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_returned,
    hvc.return_count,
    dso.d_date,
    dso.total_net_profit,
    dso.sales_rank,
    CASE 
        WHEN hvc.return_category = 'High Return' AND dso.total_net_profit IS NULL THEN 'High Return with No Sales'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    HighValuedCustomers AS hvc
CROSS JOIN 
    DailySales AS dso
WHERE 
    dso.sales_rank <= 10
ORDER BY 
    hvc.total_returned DESC, 
    dso.total_net_profit DESC;

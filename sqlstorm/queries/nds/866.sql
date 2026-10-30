WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TopCustomerReturns AS (
    SELECT 
        cr.wr_returning_customer_sk,
        cr.total_return_quantity,
        cr.total_return_amt,
        cr.total_return_tax,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS rn
    FROM 
        CustomerReturns cr
),
ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30 days'
        )
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    ac.c_first_name || ' ' || ac.c_last_name AS customer_name,
    ac.cd_gender,
    ac.cd_marital_status,
    tr.total_return_quantity,
    tr.total_return_amt,
    tr.total_return_tax,
    ss.total_net_profit,
    CASE 
        WHEN tr.total_return_amt IS NULL THEN 'No returns'
        ELSE 'Has returns'
    END AS return_status
FROM 
    ActiveCustomers ac
LEFT JOIN 
    TopCustomerReturns tr ON ac.c_customer_sk = tr.wr_returning_customer_sk
LEFT JOIN 
    SalesSummary ss ON ss.ws_ship_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date = cast('2002-10-01' as date)
    )
WHERE 
    tr.rn <= 10 OR tr.rn IS NULL
ORDER BY 
    ss.total_net_profit DESC, 
    tr.total_return_amt DESC;
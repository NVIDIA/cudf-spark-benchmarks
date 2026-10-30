WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt) AS total_return_amt, 
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        COALESCE(SUM(ws.ws_net_paid), 0) > 1000
),
ReturnStatistics AS (
    SELECT 
        chuc.c_customer_sk,
        chuc.c_first_name,
        chuc.c_last_name,
        chuc.spending_rank,
        COALESCE(cr.total_return_amt, 0) AS total_returned_amt,
        (CASE 
            WHEN COALESCE(cr.total_return_amt, 0) > 0 THEN (COALESCE(cr.total_return_amt, 0) / chuc.total_spent) * 100 
            ELSE 0 END) AS return_ratio
    FROM 
        HighValueCustomers chuc
    LEFT JOIN 
        CustomerReturns cr ON chuc.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.spending_rank,
    r.total_returned_amt,
    r.return_ratio,
    w.w_warehouse_name,
    CASE 
        WHEN r.return_ratio > 50 THEN 'High Risk'
        WHEN r.return_ratio BETWEEN 20 AND 50 THEN 'Moderate Risk'
        ELSE 'Low Risk' 
    END AS risk_category
FROM 
    ReturnStatistics r
JOIN 
    warehouse w ON r.c_customer_sk % 10 = w.w_warehouse_sk % 10  
WHERE 
    r.return_ratio IS NOT NULL 
ORDER BY 
    r.total_returned_amt DESC
LIMIT 10;
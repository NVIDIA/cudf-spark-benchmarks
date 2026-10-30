
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
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalReturnAmounts AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        tr.total_return_amt
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        TotalReturnAmounts tr ON rc.c_customer_sk = tr.sr_customer_sk
    WHERE 
        rc.rnk <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN tc.total_return_amt > 1000 THEN 'High Return'
        WHEN tc.total_return_amt BETWEEN 500 AND 1000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    sm.sm_carrier,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_return_amt, sm.sm_carrier
ORDER BY 
    total_return_amt DESC, tc.c_last_name ASC;

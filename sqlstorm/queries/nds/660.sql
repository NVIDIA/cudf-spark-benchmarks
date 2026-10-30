
WITH TotalReturns AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amt_inc_tax,
        sr_customer_sk,
        sr_store_sk
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, sr_store_sk
),
TopCustomers AS (
    SELECT 
        sr_customer_sk,
        RANK() OVER (ORDER BY total_return_amt_inc_tax DESC) AS rank
    FROM 
        TotalReturns
    WHERE 
        total_return_amt_inc_tax > 0
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_order_value,
    tr.total_return_quantity,
    tr.total_return_amt_inc_tax
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesDetails AS sd ON c.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    TotalReturns AS tr ON c.c_customer_sk = tr.sr_customer_sk
WHERE 
    c.c_birth_year < 1990 
    AND cd.cd_marital_status = 'M'
    AND c.c_current_addr_sk IS NOT NULL 
    AND EXISTS (
        SELECT 1 
        FROM TopCustomers tc WHERE tc.sr_customer_sk = c.c_customer_sk AND tc.rank <= 10
    )
ORDER BY 
    total_return_amt_inc_tax DESC NULLS LAST;

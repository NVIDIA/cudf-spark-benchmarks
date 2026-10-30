
WITH RankedReturns AS (
    SELECT 
        wr.wr_returning_customer_sk, 
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY wr.wr_returning_customer_sk ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_returning_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_date,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    CONCAT(cd.c_first_name, ' ', cd.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_profit,
    sd.order_count,
    sd.avg_net_paid,
    CASE 
        WHEN rr.total_return_amt IS NULL THEN 0 
        ELSE rr.total_return_amt 
    END AS total_return_amt,
    rr.return_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    RankedReturns rr ON cd.c_customer_sk = rr.wr_returning_customer_sk
WHERE 
    cd.gender_rank < 100 AND 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY 
    total_profit DESC,
    cd.c_customer_sk;

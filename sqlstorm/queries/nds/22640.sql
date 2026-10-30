
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 10000
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_item_sk
    HAVING 
        SUM(ws.ws_net_profit) > (
            SELECT 
                AVG(ws_inner.ws_net_profit) 
            FROM 
                web_sales ws_inner 
            WHERE 
                ws_inner.ws_bill_customer_sk = c.c_customer_sk
        )
),
BestCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_net_profit
    FROM 
        CustomerSales
    WHERE 
        rank <= 3
),
TopReasons AS (
    SELECT 
        sr_reason_sk,
        r.r_reason_desc, 
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        sr_reason_sk, r.r_reason_desc
    HAVING 
        SUM(sr_return_quantity) > 10
),
ReturnsAnalysis AS (
    SELECT 
        sr.sr_customer_sk AS c_customer_sk,
        bc.c_first_name,
        bc.c_last_name,
        tr.r_reason_desc,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    JOIN 
        BestCustomers bc ON sr.sr_customer_sk = bc.c_customer_sk 
    JOIN 
        TopReasons tr ON sr.sr_reason_sk = tr.sr_reason_sk
    GROUP BY 
        sr.sr_customer_sk, bc.c_first_name, bc.c_last_name, tr.r_reason_desc
)
SELECT 
    ra.c_customer_sk,
    ra.c_first_name,
    ra.c_last_name,
    ra.r_reason_desc,
    ra.total_returns,
    CASE 
        WHEN ra.total_return_amount IS NULL THEN 'No Returns'
        WHEN ra.total_return_amount > 1000 THEN 'High Returns'
        ELSE 'Normal Returns' 
    END AS return_type
FROM 
    ReturnsAnalysis ra
WHERE 
    ra.total_returns > 5
ORDER BY 
    ra.c_customer_sk, ra.total_returns DESC
LIMIT 10 OFFSET 5;

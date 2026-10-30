
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ReturnData AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
CombinedData AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.avg_web_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN cs.total_web_sales > 0 THEN ROUND(COALESCE(rd.total_returns, 0) * 100.0 / cs.total_web_sales, 2)
            ELSE NULL 
        END AS return_rate
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnData rd ON cs.c_customer_sk = rd.sr_customer_sk
),
RankedData AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_sales DESC) AS sales_rank
    FROM 
        CombinedData
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.total_web_sales,
    c.avg_web_profit,
    c.total_returns,
    c.total_return_amt,
    c.return_rate
FROM 
    RankedData c
WHERE 
    c.sales_rank <= 10
    AND (c.total_web_sales > 1000 OR c.return_rate IS NULL)
ORDER BY 
    c.total_web_sales DESC, c.avg_web_profit DESC;


WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
ItemReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
PerformanceBenchmark AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity,
        cs.total_net_paid,
        COALESCE(ir.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ir.return_count, 0) AS return_count,
        cs.total_net_paid - COALESCE(ir.total_return_quantity, 0) * (cs.total_net_paid / NULLIF(cs.total_quantity, 0)) AS net_performance
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ItemReturns ir ON cs.c_customer_sk = ir.wr_returning_customer_sk
)
SELECT 
    p.c_first_name,
    p.c_last_name,
    p.total_quantity,
    p.total_net_paid,
    p.total_return_quantity,
    p.return_count,
    RANK() OVER (ORDER BY p.net_performance DESC) AS performance_rank
FROM 
    PerformanceBenchmark p
WHERE 
    p.total_quantity > 0 
    AND p.net_performance > 0 
ORDER BY 
    p.net_performance DESC
LIMIT 100;

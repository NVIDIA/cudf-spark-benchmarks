
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_per_item,
        COALESCE(NULLIF(AVG(ws.ws_sales_price), 0), -1) AS avg_sales_price,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.ws_order_number, 
        ws.ws_item_sk
),

ItemReturnStats AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),

CombinedStats AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.rank_per_item,
        s.avg_sales_price,
        s.max_profit,
        COALESCE(i.total_returns, 0) AS total_returns,
        COALESCE(i.total_return_amt, 0) AS total_return_amt,
        i.return_count
    FROM 
        RankedSales s
    LEFT JOIN 
        ItemReturnStats i ON s.ws_item_sk = i.wr_item_sk
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(stats.total_quantity, 0) AS sales_quantity,
    COALESCE(stats.total_returns, 0) AS returns_quantity,
    ROUND((COALESCE(stats.total_returns, 0) * 100.0) / NULLIF(stats.total_quantity, 0), 2) AS return_rate,
    CASE 
        WHEN stats.return_count > 0 THEN 'Returned Customer'
        ELSE 'New Customer'
    END AS customer_type,
    RANK() OVER (ORDER BY ROUND((COALESCE(stats.total_returns, 0) * 100.0) / NULLIF(stats.total_quantity, 0), 2) DESC) AS return_rate_rank
FROM 
    customer c
JOIN 
    CombinedStats stats ON c.c_customer_sk = stats.ws_item_sk
WHERE 
    stats.total_quantity > 0
ORDER BY 
    return_rate_rank, stats.total_quantity DESC;

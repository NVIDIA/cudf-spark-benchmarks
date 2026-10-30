
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        RANK() OVER (ORDER BY SUM(COALESCE(ss.ss_net_profit, 0)) DESC) AS sales_rank
    FROM 
        customer c 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_sales,
        ss.total_transactions
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_sk = c.c_customer_sk
    WHERE 
        ss.total_sales > 1000
),
returns_summary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
customer_analysis AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_sales,
        hvc.total_transactions,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN hvc.total_sales - COALESCE(rs.total_return_amount, 0) > 0 THEN 'Profitable'
            ELSE 'Not Profitable'
        END AS profitability_status
    FROM 
        high_value_customers hvc
    LEFT JOIN 
        returns_summary rs ON hvc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 5000 THEN 'Top Tier'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Mid Tier'
        ELSE 'Low Tier'
    END AS customer_tier
FROM 
    customer_analysis
ORDER BY 
    total_sales DESC
LIMIT 10;

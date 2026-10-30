
WITH  SalesStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS ticket_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ReturnStats AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returns,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CombinedStats AS (
    SELECT 
        ss.c_customer_sk,
        ss.total_sales,
        ss.ticket_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count,
        ss.total_sales - COALESCE(rs.total_returns, 0) AS net_sales,
        CASE 
            WHEN rs.return_count > 0 THEN (rs.total_returns / rs.return_count)
            ELSE NULL 
        END AS avg_return_value
    FROM 
        SalesStats ss
    LEFT JOIN 
        ReturnStats rs ON ss.c_customer_sk = rs.cr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.ticket_count,
        cs.total_returns,
        cs.net_sales,
        cs.avg_return_value,
        RANK() OVER (ORDER BY cs.net_sales DESC) AS sales_rank
    FROM 
        CombinedStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.net_sales > 1000
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.net_sales,
    t.sales_rank,
    CASE 
        WHEN t.avg_return_value IS NOT NULL THEN 
            CONCAT('Average Return: $', ROUND(t.avg_return_value, 2))
        ELSE 
            'No Returns'
    END AS return_info
FROM 
    TopCustomers t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.net_sales DESC;

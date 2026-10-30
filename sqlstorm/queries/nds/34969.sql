
WITH  SalesCTE AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
ReturningSales AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_amount) AS total_returns,
        COUNT(cr_order_number) AS return_transactions
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
SalesAndReturns AS (
    SELECT 
        cte.ss_item_sk,
        cte.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        cte.total_transactions,
        cte.sales_rank
    FROM 
        SalesCTE cte
    LEFT JOIN 
        ReturningSales rs ON cte.ss_item_sk = rs.cr_item_sk
    WHERE 
        cte.sales_rank <= 10
)
SELECT 
    sa.ss_item_sk,
    sa.total_sales,
    sa.total_returns,
    sa.total_transactions,
    sa.sales_rank,
    CASE 
        WHEN sa.total_returns > 0 THEN 
            (sa.total_returns / NULLIF(sa.total_sales, 0)) * 100 
        ELSE 
            0 
    END AS return_percentage,
    CONCAT('Item ', CAST(sa.ss_item_sk AS STRING), ' has ', 
           CAST(sa.total_sales AS STRING), ' in sales with ', 
           CAST(sa.total_returns AS STRING), ' in returns.') AS sales_summary
FROM 
    SalesAndReturns sa
ORDER BY 
    sa.sales_rank;

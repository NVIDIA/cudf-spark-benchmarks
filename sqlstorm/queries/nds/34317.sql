
WITH  Sales_CTE AS (
    SELECT 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
),
Return_CTE AS (
    SELECT 
        wr_order_number,
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_order_number
),
Sales_Analysis AS (
    SELECT 
        s.ws_order_number,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales,
        CASE 
            WHEN (s.total_sales - COALESCE(r.total_returns, 0)) > 1000 THEN 'High'
            WHEN (s.total_sales - COALESCE(r.total_returns, 0)) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        Sales_CTE s
    LEFT JOIN 
        Return_CTE r ON s.ws_order_number = r.wr_order_number
),
Filtered_Sales AS (
    SELECT 
        ws_order_number,
        total_sales,
        total_returns,
        net_sales,
        sales_category
    FROM 
        Sales_Analysis
    WHERE 
        net_sales > 0
)
SELECT 
    f.ws_order_number,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    f.sales_category,
    DENSE_RANK() OVER (ORDER BY f.net_sales DESC) AS sales_rank
FROM 
    Filtered_Sales f
ORDER BY 
    f.net_sales DESC
LIMIT 100;

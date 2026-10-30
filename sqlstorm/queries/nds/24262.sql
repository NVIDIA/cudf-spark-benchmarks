
WITH  revenue_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
store_revenue AS (
    SELECT 
        ss_sold_date_sk,
        SUM(ss_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk
),
return_summary AS (
    SELECT 
        cr_returned_date_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax
    FROM 
        catalog_returns
    GROUP BY 
        cr_returned_date_sk
),
final_summary AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(re.total_sales, 0) AS web_sales,
        COALESCE(st.total_store_sales, 0) AS store_sales,
        COALESCE(rs.total_return_amount, 0) AS catalog_returns,
        (COALESCE(re.total_sales, 0) + COALESCE(st.total_store_sales, 0) - COALESCE(rs.total_return_amount, 0)) AS net_revenue,
        COALESCE(rs.return_count, 0) AS returns,
        CASE 
            WHEN COALESCE(re.total_sales, 0) + COALESCE(st.total_store_sales, 0) = 0 THEN NULL 
            ELSE (COALESCE(re.total_sales, 0) + COALESCE(st.total_store_sales, 0) - COALESCE(rs.total_return_amount, 0)) / 
                 (COALESCE(re.total_sales, 0) + COALESCE(st.total_store_sales, 0)) 
        END AS revenue_ratio
    FROM 
        date_dim d
    LEFT JOIN 
        revenue_summary re ON d.d_date_sk = re.ws_sold_date_sk
    LEFT JOIN 
        store_revenue st ON d.d_date_sk = st.ss_sold_date_sk
    LEFT JOIN 
        return_summary rs ON d.d_date_sk = rs.cr_returned_date_sk
)
SELECT 
    f.sales_date,
    f.web_sales,
    f.store_sales,
    f.catalog_returns,
    f.net_revenue,
    f.returns,
    f.revenue_ratio,
    CASE 
        WHEN f.net_revenue < 0 THEN 'Negligent Revenue'
        WHEN f.net_revenue < 1000 THEN 'Low Revenue'
        WHEN f.net_revenue < 5000 THEN 'Moderate Revenue'
        ELSE 'High Revenue' 
    END AS revenue_category
FROM 
    final_summary f
WHERE 
    f.sales_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    f.sales_date DESC
LIMIT 100;

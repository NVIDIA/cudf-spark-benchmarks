
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk ASC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
Daily_Sales AS (
    SELECT 
        dd.d_date,
        SUM(s.total_sales) AS daily_total_sales
    FROM 
        date_dim dd
    LEFT JOIN 
        Sales_CTE s ON s.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
),
Top_Sales AS (
    SELECT 
        d.d_date,
        d.daily_total_sales,
        RANK() OVER (ORDER BY d.daily_total_sales DESC) AS sales_rank
    FROM 
        Daily_Sales d
)
SELECT 
    t.d_date,
    t.daily_total_sales,
    CASE 
        WHEN t.sales_rank <= 10 THEN 'Top 10 Sales'
        ELSE 'Others'
    END AS sales_category,
    (SELECT COUNT(*) FROM store WHERE s_state = 'CA') AS total_stores_CA,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year IS NOT NULL) AS total_customers_with_birth_year,
    COALESCE((SELECT AVG(cr_return_amount) FROM catalog_returns WHERE cr_returning_customer_sk IN 
              (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk IS NOT NULL)), 0) AS avg_return_amount
FROM 
    Top_Sales t
WHERE 
    t.sales_rank <= 20
ORDER BY 
    t.daily_total_sales DESC;

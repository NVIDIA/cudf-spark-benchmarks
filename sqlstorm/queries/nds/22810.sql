
WITH Ranked_Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_sales_price, 0)) DESC) AS sales_rank,
        c.c_birth_year,
        EXTRACT(YEAR FROM DATE '2002-10-01') - c.c_birth_year AS age
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_birth_year
),
Filtered_Customers AS (
    SELECT 
        ccs.c_customer_id,
        ccs.total_sales,
        ccs.sales_rank,
        ccs.age,
        CASE 
            WHEN ccs.age IS NULL THEN 'Unknown'
            WHEN ccs.age < 18 THEN 'Minor'
            WHEN ccs.age BETWEEN 18 AND 35 THEN 'Young Adult'
            WHEN ccs.age BETWEEN 36 AND 65 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group
    FROM Ranked_Customer_Sales ccs
    WHERE ccs.total_sales > (SELECT AVG(total_sales) FROM Ranked_Customer_Sales)
),
Store_Sales_Summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    GROUP BY ss_store_sk
),
Combined_Results AS (
    SELECT 
        f.c_customer_id, 
        f.total_sales,
        f.age_group,
        s.total_store_sales,
        s.total_transactions,
        CASE 
            WHEN s.total_store_sales > 100000 THEN 'High Revenue Store'
            ELSE 'Standard Revenue Store'
        END AS revenue_category
    FROM Filtered_Customers f
    LEFT JOIN Store_Sales_Summary s ON f.sales_rank = s.ss_store_sk
)
SELECT 
    cr.c_customer_id,
    cr.total_sales,
    cr.age_group,
    COALESCE(sr.total_store_sales, 0) AS relevant_store_sales,
    COALESCE(sr.total_transactions, 0) AS relevant_store_transactions
FROM Combined_Results cr
FULL OUTER JOIN Store_Sales_Summary sr ON cr.total_store_sales < sr.total_store_sales
WHERE (cr.age_group = 'Young Adult' OR cr.revenue_category = 'High Revenue Store')
AND (cr.total_sales IS NOT NULL OR sr.total_store_sales IS NOT NULL)
ORDER BY cr.total_sales DESC NULLS LAST
LIMIT 100;


WITH  Sales_CTE AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity) AS total_sales,
        ws_item_sk,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk, ws_sold_date_sk
    HAVING 
        SUM(ws_quantity) > 10
    UNION ALL
    SELECT 
        cs_order_number,
        SUM(cs_quantity) AS total_sales,
        cs_item_sk,
        cs_sold_date_sk
    FROM 
        catalog_sales
    GROUP BY 
        cs_order_number, cs_item_sk, cs_sold_date_sk
    HAVING 
        SUM(cs_quantity) > 10
),
Ranked_Sales AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(sc.total_sales) AS total_quantity,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(sc.total_sales) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        Sales_CTE sc ON c.c_customer_sk = sc.ws_item_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Filtered_Customers AS (
    SELECT 
        rc.c_first_name,
        rc.c_last_name,
        rc.total_quantity
    FROM 
        Ranked_Sales rc
    WHERE 
        rc.sales_rank <= 10
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.total_quantity,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(ib.ib_upper_bound, 100000) AS income_upper_bound,
    DENSE_RANK() OVER (ORDER BY fc.total_quantity DESC) AS income_rank
FROM 
    Filtered_Customers fc
LEFT JOIN 
    household_demographics hd ON fc.total_quantity >= hd.hd_dep_count
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    fc.total_quantity BETWEEN 100 AND 1000
ORDER BY 
    income_rank, fc.total_quantity DESC;

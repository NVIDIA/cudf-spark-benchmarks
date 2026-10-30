
WITH  Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    
    UNION ALL
    
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
Customer_Status AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.sales_rank, 0) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        (SELECT 
             ws_bill_customer_sk,
             SUM(ws_ext_sales_price) AS total_sales,
             ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
         FROM 
             web_sales
         GROUP BY 
             ws_bill_customer_sk) s ON c.c_customer_sk = s.ws_bill_customer_sk
),
IncomeBracket AS (
    SELECT 
        h.hd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL THEN CONCAT('Income range: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound) 
            ELSE 'Unknown Income Range' 
        END AS income_bracket
    FROM 
        household_demographics h
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
),
Sales_Analysis AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.sales_rank,
        ib.income_bracket
    FROM 
        Customer_Status cs
    LEFT JOIN 
        IncomeBracket ib ON cs.c_customer_sk = ib.hd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM Sales_CTE) 
        AND cs.sales_rank < 6
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.total_sales,
    sa.income_bracket,
    CASE 
        WHEN sa.total_sales IS NULL THEN 'No Sales'
        WHEN sa.total_sales < 1000 THEN 'Low Value Customer'
        WHEN sa.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM 
    Sales_Analysis sa
ORDER BY 
    sa.total_sales DESC
LIMIT 20;

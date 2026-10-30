
WITH  Sales_Rank AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_ext_sales_price) > 10000
),
Customer_Income AS (
    SELECT 
        c.c_customer_sk,
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'UNKNOWN'
            ELSE CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_band
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd 
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib 
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Returns_Count AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
Web_Returns_Count AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_item_sk) AS web_return_count,
        SUM(wr_return_amt) AS total_web_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SALES_RANK.total_sales, 0) AS total_web_sales,
    COALESCE(WEB_RETURNS.total_web_returns, 0) AS total_web_returns,
    COALESCE(RETURNS.return_count, 0) AS total_store_returns,
    ci.income_band
FROM 
    customer c
LEFT JOIN 
    Sales_Rank SALES_RANK ON c.c_customer_sk = SALES_RANK.ws_bill_customer_sk
LEFT JOIN 
    Customer_Income ci ON c.c_customer_sk = ci.c_customer_sk
LEFT JOIN 
    Returns_Count RETURNS ON c.c_customer_sk = RETURNS.sr_customer_sk
LEFT JOIN 
    Web_Returns_Count WEB_RETURNS ON c.c_customer_sk = WEB_RETURNS.wr_returning_customer_sk
WHERE 
    (SALES_RANK.sales_rank <= 5 OR SALES_RANK.sales_rank IS NULL)
    AND (RETURNS.return_count > 3 OR COALESCE(RETURNS.total_returns, 0) > 100)
ORDER BY 
    total_web_sales DESC, 
    total_store_returns DESC;

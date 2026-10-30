
WITH  sales_cte AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_date_sk
),
sales_with_returns AS (
    SELECT 
        s.ws_ship_date_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns
    FROM 
        sales_cte s
    LEFT JOIN (
        SELECT 
            wr_returned_date_sk,
            SUM(wr_return_quantity) AS total_returns
        FROM 
            web_returns
        GROUP BY 
            wr_returned_date_sk
    ) r ON s.ws_ship_date_sk = r.wr_returned_date_sk
),
customer_income AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    d.d_date AS sales_date,
    sw.total_sales,
    sw.total_returns,
    (sw.total_sales - sw.total_returns) AS net_sales,
    ci.income_band
FROM 
    sales_with_returns sw
JOIN date_dim d ON sw.ws_ship_date_sk = d.d_date_sk
JOIN customer_income ci ON ci.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_ship_date_sk = sw.ws_ship_date_sk)
WHERE 
    sw.total_sales > 1000
ORDER BY 
    sales_date DESC,
    net_sales DESC
LIMIT 10;

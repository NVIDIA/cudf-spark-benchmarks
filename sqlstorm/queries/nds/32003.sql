
WITH  Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
Top_Daily_Sales AS (
    SELECT 
        d.d_date,
        s.total_sales,
        CASE 
            WHEN s.sales_rank = 1 THEN 'Top'
            ELSE 'Not Top'
        END AS sales_category
    FROM 
        date_dim d
    JOIN 
        Sales_CTE s ON d.d_date_sk = s.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Overall_Sales_Stats AS (
    SELECT 
        SUM(total_web_sales) AS overall_web_sales,
        SUM(total_store_sales) AS overall_store_sales,
        SUM(total_web_returns) AS overall_web_returns,
        SUM(total_store_returns) AS overall_store_returns
    FROM 
        Customer_Sales
),
Income_Band_Aggregate AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    t.d_date,
    t.total_sales,
    s.overall_web_sales,
    s.overall_store_sales,
    s.overall_web_returns,
    s.overall_store_returns,
    COALESCE(iba.customer_count, 0) AS customer_count,
    COALESCE(iba.average_purchase_estimate, 0) AS average_purchase_estimate
FROM 
    Top_Daily_Sales t
JOIN 
    Overall_Sales_Stats s ON t.d_date = (SELECT MAX(d_date) FROM Top_Daily_Sales)
LEFT JOIN 
    Income_Band_Aggregate iba ON iba.ib_income_band_sk = (SELECT MIN(ib_income_band_sk) FROM income_band)
WHERE 
    t.sales_category = 'Top'
ORDER BY 
    t.d_date DESC;

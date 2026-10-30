
WITH  IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
), CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
), SalesWithIncome AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN cs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound THEN 'Within Band'
            ELSE 'Out of Band'
        END AS sales_band_status
    FROM CustomerSales cs
    LEFT JOIN IncomeBands ib ON cs.total_sales >= ib.ib_lower_bound AND cs.total_sales <= ib.ib_upper_bound
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    sw.total_sales,
    sw.order_count,
    sw.sales_band_status,
    CASE 
        WHEN sw.sales_band_status = 'Within Band' THEN 'Eligible for Promotion'
        ELSE 'Not Eligible'
    END AS eligibility,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    MAX(ws.ws_sales_price) AS highest_single_sale
FROM CustomerSales cs
JOIN customer c ON cs.c_customer_id = c.c_customer_id
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN SalesWithIncome sw ON cs.c_customer_id = sw.c_customer_id
GROUP BY c.c_first_name, c.c_last_name, sw.total_sales, sw.order_count, sw.sales_band_status
HAVING MAX(ws.ws_sales_price) > (SELECT AVG(ws_sales_price) FROM web_sales)
ORDER BY eligibility DESC, total_sales DESC;

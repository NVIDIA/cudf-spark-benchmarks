
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
), 
SalesData AS (
    SELECT 
        d_year,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
), 
ReturnsData AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    JOIN web_sales ON wr_order_number = ws_order_number
    JOIN date_dim ON wr_returned_date_sk = d_date_sk
    GROUP BY d_year
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.total_dependents,
    sd.d_year,
    sd.total_sales,
    rd.total_returns,
    rd.return_count,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
FROM CustomerStats cs
CROSS JOIN SalesData sd
LEFT JOIN ReturnsData rd ON sd.d_year = rd.d_year
ORDER BY cs.cd_gender, sd.d_year;

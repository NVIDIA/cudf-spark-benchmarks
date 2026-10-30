
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        w_city,
        w_state,
        cd_gender,
        cd_marital_status,
        d_year
    FROM web_sales 
    JOIN warehouse ON ws_warehouse_sk = w_warehouse_sk
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year BETWEEN 2019 AND 2023
    GROUP BY 
        ws_sold_date_sk, 
        w_city,
        w_state,
        cd_gender, 
        cd_marital_status,
        d_year
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY w_city, w_state ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    w_city,
    w_state,
    cd_gender,
    cd_marital_status,
    total_quantity,
    total_sales
FROM RankedSales
WHERE sales_rank <= 5
ORDER BY w_state, w_city, total_sales DESC;

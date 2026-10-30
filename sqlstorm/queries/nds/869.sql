WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1 year')
),
TotalSales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_sales,
        COUNT(r.ws_order_number) AS order_count
    FROM RankedSales r 
    WHERE r.rn = 1
    GROUP BY r.ws_item_sk
),
CustomerGender AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS gender_order_count
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE d.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, d.cd_gender
),
SalesInformation AS (
    SELECT 
        COALESCE(cg.cd_gender, 'Unknown') AS gender,
        ts.total_sales,
        ts.order_count,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalSales ts
    LEFT JOIN CustomerGender cg ON ts.ws_item_sk = cg.c_customer_sk
)
SELECT 
    gender,
    AVG(total_sales) AS avg_sales,
    SUM(order_count) AS total_orders,
    MAX(sales_rank) AS max_rank
FROM SalesInformation
WHERE sales_rank <= 10
GROUP BY gender
ORDER BY avg_sales DESC;
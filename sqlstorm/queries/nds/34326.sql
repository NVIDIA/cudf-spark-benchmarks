
WITH  SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT
        ws_item_sk,
        total_sales
    FROM SalesData
    WHERE sales_rank <= 10
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT
        ca_state,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_state
)
SELECT
    s.ca_state,
    s.total_sales,
    COALESCE(d.order_count, 0) AS order_count,
    CASE 
        WHEN s.avg_sales > 100 THEN 'High'
        WHEN s.avg_sales BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM SalesSummary s
LEFT JOIN CustomerDetails d ON s.ca_state = d.c_customer_id
WHERE s.total_sales > 5000
ORDER BY s.total_sales DESC
LIMIT 50;


WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.order_count
    FROM RankedSales r
    JOIN customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE r.rank <= 10
),
SalesByRegion AS (
    SELECT 
        ca_state,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ca_state
),
SalesAgainstDemographics AS (
    SELECT 
        cd_gender,
        AVG(total_sales) AS avg_sales,
        SUM(total_sales) AS total_sales
    FROM (
        SELECT 
            ws.ws_bill_customer_sk,
            SUM(ws.ws_sales_price) AS total_sales,
            cd.cd_gender
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
        GROUP BY ws.ws_bill_customer_sk, cd.cd_gender
    ) AS demographics
    GROUP BY cd_gender
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    r.total_sales AS regional_sales,
    dg.cd_gender,
    dg.avg_sales,
    dg.total_sales AS gender_total_sales
FROM TopCustomers tc
LEFT JOIN SalesByRegion r ON r.total_sales > 0
LEFT JOIN SalesAgainstDemographics dg ON dg.total_sales > 0
ORDER BY tc.total_sales DESC, dg.avg_sales DESC;

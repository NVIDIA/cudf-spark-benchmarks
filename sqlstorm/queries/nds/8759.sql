
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_web_page_sk) AS distinct_web_pages,
        AVG(ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 90 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT customer_id, total_sales, total_orders, distinct_web_pages, avg_net_profit
    FROM SalesSummary
    WHERE rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        AVG(total_orders) AS avg_orders,
        AVG(distinct_web_pages) AS avg_distinct_pages,
        AVG(avg_net_profit) AS avg_profit
    FROM TopCustomers
    JOIN customer_demographics ON customer_demographics.cd_demo_sk = TopCustomers.customer_id
    GROUP BY cd_gender
)
SELECT 
    cd_gender,
    customer_count,
    avg_sales,
    avg_orders,
    avg_distinct_pages,
    avg_profit
FROM CustomerDemographics
ORDER BY cd_gender;

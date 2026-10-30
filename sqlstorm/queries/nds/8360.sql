
WITH SalesSummary AS (
    SELECT
        ca_state,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS avg_sale_value,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    LEFT JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2023
    GROUP BY ca_state
),
TopStates AS (
    SELECT
        ca_state,
        total_sales,
        order_count,
        avg_sale_value,
        unique_customers,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesSummary
),
RevenueGrowth AS (
    SELECT
        state1.ca_state AS state,
        state1.total_sales AS current_year_sales,
        state2.total_sales AS previous_year_sales,
        (state1.total_sales - state2.total_sales) / NULLIF(state2.total_sales, 0) AS growth_rate
    FROM TopStates AS state1
    JOIN SalesSummary AS state2 ON state1.ca_state = state2.ca_state
    WHERE state2.unique_customers > 0 AND state1.sales_rank <= 5
)
SELECT
    state,
    current_year_sales,
    previous_year_sales,
    growth_rate
FROM RevenueGrowth
ORDER BY growth_rate DESC;

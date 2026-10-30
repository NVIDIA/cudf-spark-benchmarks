
WITH customer_stats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM customer_address
    JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY ca_state
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    GROUP BY d_year
),
state_sales AS (
    SELECT 
        ca_state,
        SUM(ss_sales_price) AS state_sales,
        SUM(ss_net_profit) AS state_profit
    FROM store_sales
    JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY ca_state
)
SELECT 
    cs.ca_state,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.avg_dep_count,
    COALESCE(ss.state_sales, 0) AS total_sales_in_state,
    COALESCE(ss.state_profit, 0) AS total_profit_in_state
FROM customer_stats cs
LEFT JOIN state_sales ss ON cs.ca_state = ss.ca_state
ORDER BY cs.customer_count DESC, total_sales_in_state DESC
LIMIT 20;

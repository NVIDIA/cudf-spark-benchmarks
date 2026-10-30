
WITH  sales_data AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2000)
    GROUP BY ss_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ci.ca_state,
        ci.cd_gender,
        SUM(sd.total_sales) AS state_total_sales,
        SUM(sd.total_quantity) AS state_total_quantity,
        AVG(sd.total_sales) AS avg_sales_per_item
    FROM sales_data sd
    JOIN store s ON sd.ss_item_sk = s.s_store_sk
    JOIN customer_info ci ON s.s_store_sk = ci.c_customer_sk
    GROUP BY ci.ca_state, ci.cd_gender
)

SELECT 
    s.ca_state,
    s.cd_gender,
    s.state_total_sales,
    s.state_total_quantity,
    s.avg_sales_per_item,
    CASE 
        WHEN s.state_total_sales > 100000 THEN 'High Sales'
        WHEN s.state_total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM sales_summary s
WHERE s.state_total_quantity > (
        SELECT AVG(state_total_quantity) FROM sales_summary
)
ORDER BY s.state_total_sales DESC;

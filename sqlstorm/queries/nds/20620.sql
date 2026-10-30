
WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_college_count) AS total_college_dependents
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
item_statistics AS (
    SELECT 
        i_category AS item_category,
        COUNT(i_item_sk) AS item_count,
        SUM(i_current_price) AS total_value,
        MIN(i_current_price) AS min_price,
        AVG(i_current_price) AS avg_price,
        MAX(i_current_price) AS max_price
    FROM 
        item
    GROUP BY 
        i_category
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DATE '2002-10-01' AS report_date
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
combined_report AS (
    SELECT 
        da.cd_gender,
        da.customer_count,
        da.avg_purchase_estimate,
        i.item_category,
        i.item_count,
        i.total_value,
        i.min_price,
        i.avg_price,
        i.max_price,
        s.total_sales,
        s.order_count
    FROM 
        demographic_analysis da
    CROSS JOIN 
        item_statistics i
    JOIN 
        sales_summary s ON s.ws_bill_customer_sk = (
            SELECT c_customer_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL LIMIT 1
        )
    WHERE 
        da.customer_count > 0 AND i.item_count > 0
        AND da.avg_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
)
SELECT 
    cd_gender,
    SUM(customer_count) AS total_customers,
    AVG(avg_purchase_estimate) AS average_estimates,
    COUNT(DISTINCT item_category) AS distinct_categories,
    SUM(total_value) AS total_item_value,
    MIN(min_price) AS lowest_price,
    AVG(avg_price) AS average_item_price,
    MAX(max_price) AS highest_price,
    SUM(total_sales) AS total_sales,
    SUM(order_count) AS total_orders
FROM 
    combined_report
GROUP BY 
    cd_gender
HAVING 
    SUM(customer_count) > 10
ORDER BY 
    total_sales DESC, average_item_price ASC
LIMIT 10;

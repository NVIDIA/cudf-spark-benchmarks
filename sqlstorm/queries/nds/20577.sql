WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS dense_rnk,
        ws_ext_sales_price,
        CASE 
            WHEN ws_sales_price IS NULL THEN 'No Price' 
            WHEN ws_sales_price = 0 THEN 'Free' 
            ELSE 'Paid' 
        END AS price_status
    FROM web_sales
),
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        MAX(price_status) AS max_price_status
    FROM RankedSales
    GROUP BY ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesWithCustomer AS (
    SELECT 
        a.ws_item_sk,
        a.total_sales,
        a.total_orders,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.buy_potential,
        c.purchase_estimate
    FROM AggregatedSales a
    JOIN web_sales w ON a.ws_item_sk = w.ws_item_sk
    JOIN CustomerInfo c ON w.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.total_orders,
    COALESCE(s.c_customer_sk, -1) AS customer_id,
    s.c_first_name,
    s.c_last_name,
    CASE 
        WHEN s.total_orders > 10 THEN 'High Frequency' 
        WHEN s.total_orders BETWEEN 5 AND 10 THEN 'Medium Frequency' 
        ELSE 'Low Frequency' 
    END AS order_frequency,
    MAX(s.purchase_estimate) AS max_purchase_estimate,
    s.buy_potential
FROM SalesWithCustomer s
GROUP BY 
    s.ws_item_sk, 
    s.total_sales, 
    s.total_orders, 
    s.c_customer_sk, 
    s.c_first_name, 
    s.c_last_name, 
    s.buy_potential
HAVING 
    SUM(s.total_sales) > 100
ORDER BY 
    s.total_sales DESC
LIMIT 50;
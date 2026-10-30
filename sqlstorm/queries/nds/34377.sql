
WITH  SalesHierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    UNION ALL
    SELECT 
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rn
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
CustomerMetrics AS (
    SELECT 
        ch.customer_sk,
        ch.total_sales,
        ch.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        (SELECT COUNT(*) FROM customer_address ca 
         WHERE ca.ca_address_sk = c.c_current_addr_sk) AS address_count
    FROM 
        SalesHierarchy ch
    JOIN 
        customer c ON ch.customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ch.rn = 1
),
FilteredMetrics AS (
    SELECT 
        cm.customer_sk,
        cm.total_sales,
        cm.order_count,
        cm.cd_gender,
        cm.cd_marital_status,
        cm.address_count,
        CASE 
            WHEN cm.total_sales IS NULL THEN 'No Sales'
            WHEN cm.total_sales < 1000 THEN 'Low Value Customer'
            WHEN cm.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
            ELSE 'High Value Customer'
        END AS customer_value_segment
    FROM 
        CustomerMetrics cm
)
SELECT 
    cm.customer_sk,
    cm.total_sales,
    cm.order_count,
    cm.cd_gender,
    cm.cd_marital_status,
    cm.address_count,
    cm.customer_value_segment
FROM 
    FilteredMetrics cm
WHERE 
    cm.customer_value_segment IN ('Medium Value Customer', 'High Value Customer')
ORDER BY 
    cm.total_sales DESC
LIMIT 100;

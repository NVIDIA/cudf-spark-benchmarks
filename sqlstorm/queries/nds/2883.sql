
WITH SalesCTE AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopSpenders AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        s.total_sales,
        s.order_count,
        s.avg_net_paid
    FROM SalesCTE s
    JOIN CustomerInfo ci ON s.ws_bill_customer_sk = ci.c_customer_sk
    WHERE s.rank_sales <= 10
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    ts.ca_city,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    COALESCE(ts.avg_net_paid, 0) AS avg_net_paid,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = ts.c_customer_sk) AS store_order_count,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = ts.c_customer_sk) AS catalog_order_count
FROM TopSpenders ts
LEFT JOIN customer_address ca ON ts.c_customer_sk = ca.ca_address_sk
ORDER BY ts.total_sales DESC;

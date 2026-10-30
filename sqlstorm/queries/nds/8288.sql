
WITH CustomerAggregate AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ss.ss_net_profit) AS total_net_profit, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
), 
TimeFrame AS (
    SELECT 
        d.d_date_sk, 
        d.d_year, 
        d.d_month_seq
    FROM date_dim d
    WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3)
), 
SalesSummary AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_sales_price) AS total_web_sales, 
        SUM(cs.cs_sales_price) AS total_catalog_sales, 
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM CustomerAggregate c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN TimeFrame tf ON ws.ws_sold_date_sk = tf.d_date_sk OR cs.cs_sold_date_sk = tf.d_date_sk OR ss.ss_sold_date_sk = tf.d_date_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.c_customer_sk, 
    ca.c_first_name, 
    ca.c_last_name, 
    ca.cd_gender, 
    ca.cd_marital_status, 
    COALESCE(ss.total_web_sales, 0) AS total_web_sales, 
    COALESCE(ss.total_catalog_sales, 0) AS total_catalog_sales, 
    COALESCE(ss.total_store_sales, 0) AS total_store_sales, 
    ca.total_net_profit, 
    ca.total_purchases
FROM CustomerAggregate ca
LEFT JOIN SalesSummary ss ON ca.c_customer_sk = ss.c_customer_sk
ORDER BY ca.total_net_profit DESC
LIMIT 50;

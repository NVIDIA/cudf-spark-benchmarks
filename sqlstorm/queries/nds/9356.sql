WITH sales_summary AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2459232 AND 2459233  
    GROUP BY cs_item_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        SUM(ss_net_profit) AS total_customer_profit
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
average_sales AS (
    SELECT
        cs.cs_item_sk,
        AVG(cs.total_sales) AS avg_daily_sales
    FROM sales_summary AS cs
    GROUP BY cs.cs_item_sk
)
SELECT
    cu.c_customer_sk,
    cu.cd_gender,
    cu.cd_marital_status,
    ss.total_quantity,
    ss.total_sales,
    ss.total_profit,
    av.avg_daily_sales
FROM customer_summary AS cu
JOIN sales_summary AS ss ON cu.c_customer_sk = ss.cs_item_sk
JOIN average_sales AS av ON ss.cs_item_sk = av.cs_item_sk
WHERE cu.total_transactions > 5
ORDER BY total_profit DESC
LIMIT 100;
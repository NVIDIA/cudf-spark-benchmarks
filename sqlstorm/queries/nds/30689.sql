
WITH  sales_data AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_quantity) DESC) AS sales_rank
    FROM
        store_sales ss
    GROUP BY
        ss.ss_item_sk, ss.ss_store_sk
),
top_sales AS (
    SELECT
        sd.ss_item_sk,
        sd.ss_store_sk,
        sd.total_sales,
        sd.total_profit
    FROM
        sales_data sd
    WHERE
        sd.sales_rank <= 5
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS web_sales_quantity,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
),
customer_engagement AS (
    SELECT
        cs.c_customer_sk,
        cs.cd_gender,
        cs.web_sales_quantity,
        cs.web_sales_profit,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.web_sales_profit DESC) AS profit_rank
    FROM
        customer_sales cs
),
final_report AS (
    SELECT 
        te.ss_item_sk,
        te.ss_store_sk,
        te.total_sales,
        te.total_profit,
        ce.cd_gender,
        ce.web_sales_quantity,
        ce.web_sales_profit,
        CASE 
            WHEN ce.web_sales_quantity IS NULL THEN 'No Sales'
            ELSE 'Sales Made'
        END AS sales_status
    FROM
        top_sales te
    FULL OUTER JOIN
        customer_engagement ce ON te.ss_store_sk = ce.c_customer_sk
)
SELECT 
    fr.ss_item_sk,
    fr.ss_store_sk,
    fr.total_sales,
    fr.total_profit,
    fr.cd_gender,
    fr.web_sales_quantity,
    fr.web_sales_profit,
    fr.sales_status
FROM 
    final_report fr
WHERE 
    (fr.total_profit > 5000 OR fr.web_sales_profit > 1000)
    AND (fr.cd_gender IS NOT NULL OR fr.total_sales IS NOT NULL)
ORDER BY 
    fr.total_profit DESC;

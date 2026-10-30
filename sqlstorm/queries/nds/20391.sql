
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate > 1000 AND cd.cd_gender IS NOT NULL
), 
aggregate_info AS (
    SELECT 
        ci.c_customer_sk,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales
    FROM customer_info ci
    LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON ci.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY ci.c_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ai.total_net_profit,
    ai.total_web_sales,
    ai.total_catalog_sales,
    (SELECT COUNT(*) FROM ranked_sales rs WHERE rs.cs_item_sk = (SELECT i.i_item_sk FROM item i WHERE i.i_manufact = 'CompanyX' LIMIT 1)) AS related_item_sales_count
FROM customer_info ci
JOIN aggregate_info ai ON ci.c_customer_sk = ai.c_customer_sk
WHERE ai.total_net_profit > (
    SELECT AVG(total_net_profit) 
    FROM aggregate_info
) AND (ai.total_web_sales + ai.total_catalog_sales) > (
    SELECT AVG(total_web_sales + total_catalog_sales) FROM aggregate_info
)
ORDER BY ai.total_net_profit DESC
LIMIT 10;

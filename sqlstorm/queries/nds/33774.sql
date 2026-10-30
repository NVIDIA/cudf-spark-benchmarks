
WITH RECURSIVE CTE AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price,
        1 AS level,
        CAST(i.i_item_desc AS STRING) AS path
    FROM 
        item i
    WHERE 
        i.i_item_desc IS NOT NULL
    UNION ALL
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price,
        CTE.level + 1,
        CONCAT(CTE.path, ' -> ', i.i_item_desc)
    FROM 
        item i
    JOIN 
        CTE ON i.i_item_sk = CTE.i_item_sk + 1  
    WHERE 
        CTE.level < 5  
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        CustomerSales csv
    JOIN 
        customer c ON csv.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        csv.total_spent > 5000
)
SELECT 
    hvc.c_customer_sk,
    hvc.ca_city,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
    COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY hvc.ca_city ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) DESC) AS city_rank
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    store_sales ss ON hvc.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    hvc.c_customer_sk, hvc.ca_city, hvc.cd_gender, hvc.cd_marital_status
HAVING 
    (COUNT(DISTINCT ws.ws_order_number) > 0 OR COUNT(DISTINCT ss.ss_ticket_number) > 0)
    AND COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) > 1000
ORDER BY 
    total_profit DESC;

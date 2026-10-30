
WITH  sales_ranking AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
), 
sales_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_sales_price) AS avg_order_value,
        COUNT(DISTINCT CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_order_number END) AS profitable_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND ca.ca_city IS NOT NULL
    GROUP BY 
        c.c_customer_id, ca.ca_city
), 
rich_customers AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    JOIN 
        customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ss.ss_net_profit) > 10000
)
SELECT 
    s.c_customer_id,
    s.ca_city,
    s.total_sales,
    s.order_count,
    s.avg_order_value,
    r.cd_gender,
    r.cd_marital_status,
    r.total_net_profit,
    COALESCE(r.total_net_profit, 0) AS net_profit_detail
FROM 
    sales_summary s
LEFT JOIN 
    rich_customers r ON s.c_customer_id = CAST(r.cd_demo_sk AS VARCHAR(16))
WHERE 
    (s.total_sales > 5000 OR r.total_net_profit IS NOT NULL)
ORDER BY 
    s.total_sales DESC, r.total_net_profit DESC;

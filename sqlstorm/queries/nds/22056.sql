
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
SalesStatistics AS (
    SELECT 
        rs.ws_item_sk,
        AVG(rs.ws_sales_price) AS avg_price,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    ss.avg_price,
    ss.total_profit,
    COALESCE(ws.ws_net_paid, 0) AS web_net_paid,
    CASE 
        WHEN cd.cd_marital_status = 'M' AND ss.total_profit > 1000 
        THEN 'High spender couple'
        WHEN cd.cd_marital_status = 'S' AND ss.total_profit <= 1000 
        THEN 'Single with moderate spending'
        ELSE 'Other categories'
    END AS customer_category
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
INNER JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesStatistics ss ON c.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk AND ws.ws_sales_price > 0
WHERE 
    ca.ca_state = 'CA'
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status IS NULL)
    AND ss.avg_price > (SELECT AVG(avg_price) FROM SalesStatistics)
ORDER BY 
    ss.total_profit DESC NULLS LAST
LIMIT 50;

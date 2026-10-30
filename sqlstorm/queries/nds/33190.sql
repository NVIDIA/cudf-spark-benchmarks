
WITH  historical_sales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
addr_info AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
),
sales_data AS (
    SELECT 
        I.i_item_desc,
        COALESCE(NULLIF(SUM(ss.ss_quantity), 0), 1) AS total_sold,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_revenue,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        item I ON I.i_item_sk = ss.ss_item_sk
    WHERE 
        ss.ss_sold_date_sk >= 1000
    GROUP BY 
        I.i_item_desc
)
SELECT 
    a.ca_city, 
    a.ca_state, 
    h.total_sales,
    s.total_profit,
    s.avg_sales_price,
    (s.total_revenue + COALESCE(NULLIF(s.total_profit, 0), 0) * 0.05) AS potential_revenue
FROM 
    addr_info a
LEFT JOIN 
    historical_sales h ON h.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_item_desc LIKE '%Coffee%')
JOIN 
    sales_data s ON s.i_item_desc LIKE CONCAT('%', a.ca_city, '%')
WHERE 
    a.customer_count > 10
ORDER BY 
    potential_revenue DESC;

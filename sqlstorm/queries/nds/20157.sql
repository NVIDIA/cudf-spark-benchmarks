
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        MAX(i.i_current_price) AS current_price,
        CASE 
            WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN 'No Sales'
            ELSE CASE 
                WHEN AVG(ws.ws_net_profit) > 500 THEN 'High Profit'
                ELSE 'Low Profit'
            END
        END AS profit_category
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
),
CustomerProfit AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT CASE WHEN ws.ws_quantity IS NULL THEN NULL ELSE ws.ws_order_number END) AS distinct_orders,
        RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        customer_demographics cd
    LEFT JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sp.total_quantity) AS total_sold,
    SUM(sp.total_profit) AS total_revenue,
    COUNT(DISTINCT cp.cd_demo_sk) AS unique_customers,
    STRING_AGG(DISTINCT CASE WHEN cp.profit_rank <= 10 THEN CONCAT('Customer ', cp.cd_demo_sk) ELSE NULL END, ', ') AS top_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    ItemSales sp ON c.c_current_cdemo_sk = sp.i_item_sk
LEFT JOIN 
    CustomerProfit cp ON c.c_current_cdemo_sk = cp.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND (cp.total_profit IS NULL OR cp.total_profit > (SELECT AVG(total_profit) FROM CustomerProfit))
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(sp.total_quantity) > (SELECT AVG(total_quantity) FROM ItemSales)
ORDER BY 
    total_revenue DESC
LIMIT 100;


WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_order_number
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_sales_price) AS average_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
JoinSales AS (
    SELECT 
        cs.cs_item_sk,
        CS.total_sales,
        COALESCE(SS.total_profit, 0) AS total_profit,
        COALESCE(SS.average_price, 0) AS average_price,
        CASE 
            WHEN SS.average_price > 0 THEN (CS.total_sales / SS.average_price)
            ELSE NULL 
        END AS sales_to_avg_price_ratio
    FROM 
        RankedSales CS
    LEFT JOIN 
        SalesSummary SS ON CS.cs_item_sk = SS.ws_item_sk
    WHERE 
        CS.rank = 1
)
SELECT 
    J.cs_item_sk,
    J.total_sales,
    J.total_profit,
    J.average_price,
    J.sales_to_avg_price_ratio,
    i.i_item_desc,
    ca.ca_city,
    ca.ca_state,
    d.d_year
FROM 
    JoinSales J
JOIN 
    item i ON J.cs_item_sk = i.i_item_sk
JOIN 
    store_sales ss ON J.cs_item_sk = ss.ss_item_sk
LEFT JOIN 
    customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    J.total_sales > 1000 AND 
    d.d_year IN (2021, 2022)
ORDER BY 
    J.total_sales DESC, J.total_profit DESC;

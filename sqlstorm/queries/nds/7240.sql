
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales 
    INNER JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        ws_item_sk
),
HighPerformingItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
CustomerEngagement AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
EngagedCustomers AS (
    SELECT 
        ce.c_customer_sk,
        ce.total_orders,
        ce.total_profit
    FROM 
        CustomerEngagement ce
    WHERE 
        ce.total_orders > 5 AND ce.total_profit > 1000
)
SELECT 
    hpi.i_item_desc,
    hpi.i_category,
    hpi.i_brand,
    ec.total_orders,
    ec.total_profit
FROM 
    HighPerformingItems hpi
JOIN 
    EngagedCustomers ec ON hpi.ws_item_sk = ec.c_customer_sk
ORDER BY 
    ec.total_profit DESC;


WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    WHERE sd.total_orders > 10
),
ProductDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price,
        tp.total_sales,
        tp.total_net_profit
    FROM item i
    JOIN TopProducts tp ON i.i_item_sk = tp.ws_item_sk
    WHERE tp.sales_rank <= 10
)
SELECT 
    pd.i_item_desc,
    pd.i_brand,
    pd.i_current_price,
    pd.total_sales,
    pd.total_net_profit
FROM ProductDetails pd
ORDER BY pd.total_sales DESC;

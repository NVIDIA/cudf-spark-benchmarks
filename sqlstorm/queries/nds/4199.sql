
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rnk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        i.i_item_desc,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND (ws.ws_ext_discount_amt > 0 OR ws.ws_net_profit < 0)
),
TopSales AS (
    SELECT 
        r.*,
        CASE 
            WHEN r.ws_ext_discount_amt > 0 THEN 'Discount Applied'
            ELSE 'No Discount'
        END AS discount_status
    FROM 
        RankedSales r
    WHERE 
        rnk = 1
)
SELECT 
    tsa.i_item_desc,
    tsa.c_customer_id,
    tsa.c_first_name,
    tsa.c_last_name,
    SUM(tsa.ws_ext_sales_price) AS total_sales,
    COUNT(tsa.ws_order_number) AS order_count,
    MAX(tsa.ws_net_profit) AS max_profit,
    MIN(tsa.ws_net_profit) AS min_profit,
    COUNT(CASE WHEN tsa.discount_status = 'Discount Applied' THEN 1 END) AS discount_count
FROM 
    TopSales tsa
GROUP BY 
    tsa.i_item_desc,
    tsa.c_customer_id,
    tsa.c_first_name,
    tsa.c_last_name
HAVING 
    SUM(tsa.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;


WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_quantity > 100
)
SELECT 
    tp.rank,
    tp.ws_item_sk,
    i.i_item_desc,
    tp.total_quantity,
    tp.total_sales,
    tp.avg_profit,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
FROM 
    TopProducts tp
JOIN 
    item i ON tp.ws_item_sk = i.i_item_sk
LEFT JOIN 
    web_sales ws ON tp.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
GROUP BY 
    tp.rank, tp.ws_item_sk, i.i_item_desc, tp.total_quantity, tp.total_sales, tp.avg_profit
HAVING 
    COUNT(DISTINCT cd.c_customer_sk) >= 5
ORDER BY 
    tp.rank;

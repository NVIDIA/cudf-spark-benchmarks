WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sale_rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_sales_price
    FROM 
        SalesData sd
    WHERE 
        sd.sale_rank <= 10
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_ordered
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(ts.total_sales), 0) AS top_sales,
    COUNT(DISTINCT ts.ws_item_sk) AS unique_items_bought
FROM 
    CustomerData cd
LEFT JOIN 
    web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    TopSales ts ON ws.ws_item_sk = ts.ws_item_sk
GROUP BY 
    cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status
HAVING 
    COALESCE(SUM(ts.total_sales), 0) > 1000
ORDER BY 
    top_sales DESC,
    cd.c_customer_sk
LIMIT 50;
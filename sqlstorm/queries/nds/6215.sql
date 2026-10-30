
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_net_profit) AS total_net_profit 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000 
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
CustomerData AS (
    SELECT 
        c_customer_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status 
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
), 
TopProducts AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity, 
        sd.total_sales, 
        sd.total_net_profit, 
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS rank 
    FROM 
        SalesData sd 
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk 
    WHERE 
        i.i_current_price > 50
)
SELECT 
    cp.c_customer_sk, 
    cp.cd_gender, 
    cp.cd_marital_status, 
    cp.cd_education_status, 
    tp.ws_item_sk, 
    tp.total_quantity, 
    tp.total_sales, 
    tp.total_net_profit 
FROM 
    TopProducts tp 
JOIN 
    CustomerData cp ON cp.c_customer_sk IN (
        SELECT DISTINCT ws_ship_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = tp.ws_item_sk
    )
WHERE 
    tp.rank <= 10 
ORDER BY 
    tp.total_net_profit DESC, 
    cp.cd_gender, 
    cp.cd_marital_status;

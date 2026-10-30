
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND i.i_brand = 'BrandX'
    GROUP BY 
        ws.ws_sold_date_sk
),
DailyStats AS (
    SELECT 
        d.d_date AS sale_date,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_discount, 0) AS total_discount,
        COALESCE(sd.total_profit, 0) AS total_profit,
        (COALESCE(sd.total_sales, 0) - COALESCE(sd.total_discount, 0)) AS net_sales
    FROM 
        date_dim d
    LEFT JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    sale_date,
    total_quantity,
    total_sales,
    total_discount,
    total_profit,
    net_sales
FROM 
    DailyStats
ORDER BY 
    sale_date;

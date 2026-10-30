
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2023 
        AND (cd.cd_gender = 'F' OR cd.cd_gender = 'M') 
        AND i.i_current_price > 0 
    GROUP BY 
        ws.ws_item_sk
), RankedSales AS (
    SELECT 
        SalesData.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_sales,
    r.avg_sales_price,
    r.order_count,
    r.sales_rank
FROM 
    RankedSales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;


WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_education_status IN ('PhD', 'Masters')
        AND i.i_current_price BETWEEN 10.00 AND 100.00
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_sales,
    sd.order_count
FROM 
    SalesData sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE 
    sd.sales_rank <= 10
ORDER BY 
    sd.total_sales DESC;

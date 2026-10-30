
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_web_site_sk
),
RankedSales AS (
    SELECT 
        sd.ws_web_site_sk,
        sd.ws_sold_date_sk,
        sd.total_sales,
        sd.total_orders,
        sd.total_quantity,
        RANK() OVER (PARTITION BY sd.ws_web_site_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        total_quantity
    FROM 
        RankedSales r
    JOIN 
        web_site w ON r.ws_web_site_sk = w.web_site_sk
    WHERE 
        sales_rank <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    tw.total_sales,
    tw.total_orders,
    tw.total_quantity
FROM 
    TopWebsites tw
JOIN 
    web_site w ON tw.web_site_id = w.web_site_id
ORDER BY 
    tw.total_sales DESC;

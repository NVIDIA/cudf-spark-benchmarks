
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        ss.ws_item_sk,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
)
SELECT 
    ts.sales_rank,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.order_count
FROM 
    TopSales ts
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales_rank;

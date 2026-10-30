
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_list_price) AS avg_list_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq IN (1, 2, 3)
    GROUP BY 
        ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_college_count) AS total_college_deps
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_list_price,
        cd.customer_count,
        cd.avg_purchase_estimate,
        cd.total_college_deps
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerData cd ON sd.ws_item_sk = cd.cd_demo_sk
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales,
    fr.avg_list_price,
    fr.customer_count,
    fr.avg_purchase_estimate,
    fr.total_college_deps
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > 10000 
ORDER BY 
    fr.total_sales DESC
LIMIT 50;

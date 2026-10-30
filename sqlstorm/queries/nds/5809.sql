
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458985 AND 2459015 
    GROUP BY 
        w.w_warehouse_id
),
DemographicData AS (
    SELECT 
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_id) AS demographic_customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sd.w_warehouse_id,
    sd.total_sales,
    sd.total_quantity,
    sd.total_orders,
    sd.avg_sales_price,
    sd.total_customers,
    dd.cd_gender,
    dd.avg_purchase_estimate,
    dd.demographic_customer_count
FROM 
    SalesData sd
CROSS JOIN 
    DemographicData dd
ORDER BY 
    sd.total_sales DESC, 
    dd.avg_purchase_estimate DESC
LIMIT 100;

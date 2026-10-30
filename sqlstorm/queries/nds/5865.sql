WITH CustomerStats AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_dep_employed_count) AS avg_employed_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
SalesData AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, 
        d.d_month_seq
),
TopSellingItems AS (
    SELECT 
        i.i_item_id, 
        SUM(ws_ext_sales_price) AS item_sales
    FROM 
        web_sales
    JOIN 
        item i ON ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        item_sales DESC
    LIMIT 10
)
SELECT 
    cs.cd_gender, 
    cs.cd_marital_status, 
    cs.customer_count, 
    cs.total_purchase_estimate, 
    cs.avg_dependents, 
    sd.d_year, 
    sd.d_month_seq, 
    sd.total_sales, 
    sd.total_orders, 
    tsi.i_item_id, 
    tsi.item_sales
FROM 
    CustomerStats cs
JOIN 
    SalesData sd ON EXTRACT(YEAR FROM cast('2002-10-01' as date)) = sd.d_year 
                   AND EXTRACT(MONTH FROM cast('2002-10-01' as date)) = sd.d_month_seq
CROSS JOIN 
    TopSellingItems tsi
WHERE 
    cs.customer_count > 50 
ORDER BY 
    cs.total_purchase_estimate DESC, 
    sd.total_sales DESC;

WITH SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        w.w_warehouse_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_item_price,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        ws.ws_ship_date_sk, w.w_warehouse_id
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_marital_status, cd.cd_gender
),
RankedSales AS (
    SELECT 
        sd.w_warehouse_id,
        sd.total_sales,
        sd.order_count,
        ROW_NUMBER() OVER (PARTITION BY sd.w_warehouse_id ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData AS sd
)
SELECT 
    rc.c_customer_sk,
    rc.cd_marital_status,
    rc.cd_gender,
    ss.w_warehouse_id,
    ss.total_sales,
    ss.order_count,
    ss.sales_rank,
    CASE 
        WHEN rc.total_spent IS NULL THEN 'No Orders'
        WHEN rc.total_spent < 1000 THEN 'Low Spender'
        WHEN rc.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spender_category
FROM 
    CustomerData AS rc
JOIN 
    RankedSales AS ss ON rc.order_count > 5
WHERE 
    EXISTS (
        SELECT 1
        FROM SalesData AS sd
        WHERE sd.ws_ship_date_sk = rc.c_customer_sk
        AND sd.total_sales > 1000
    )
ORDER BY 
    ss.sales_rank, rc.total_spent DESC;

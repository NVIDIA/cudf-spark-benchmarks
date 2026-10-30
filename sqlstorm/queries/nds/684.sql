
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank,
        MAX(cd.cd_purchase_estimate) AS max_estimate
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        w.w_warehouse_name IS NOT NULL 
        AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451547
    GROUP BY 
        w.w_warehouse_name
), RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS overall_rank
    FROM 
        SalesData
)
SELECT 
    r.w_warehouse_name,
    r.total_sales,
    r.average_profit,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_category,
    COALESCE(s.max_estimate, 0) AS customer_max_estimate
FROM 
    RankedSales r
LEFT JOIN 
    (SELECT 
         w.w_warehouse_name,
         MAX(cd.cd_purchase_estimate) AS max_estimate
     FROM 
         web_sales ws
     JOIN 
         warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
     JOIN 
         customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
     LEFT JOIN 
         customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
     WHERE
         ws.ws_sold_date_sk BETWEEN 2451545 AND 2451547
     GROUP BY 
         w.w_warehouse_name) s ON r.w_warehouse_name = s.w_warehouse_name
WHERE 
    r.overall_rank <= 10
ORDER BY 
    r.total_sales DESC;

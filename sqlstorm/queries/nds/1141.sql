
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910  
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.c_customer_id ORDER BY sd.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        SalesData sd
),
TotalSales AS (
    SELECT 
        c_customer_id AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        RankedSales
    GROUP BY 
        c_customer_id
),
FilteredSales AS (
    SELECT 
        ts.customer_id,
        ts.total_sales,
        ts.total_orders,
        CASE 
            WHEN ts.total_sales > 5000 THEN 'High Value'
            WHEN ts.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        TotalSales ts
    WHERE 
        ts.total_orders > 2
)

SELECT 
    fs.customer_id,
    fs.total_sales,
    fs.total_orders,
    fs.customer_value,
    COUNT(rs.ws_order_number) AS order_count_ranked
FROM 
    FilteredSales fs
LEFT JOIN 
    RankedSales rs ON fs.customer_id = rs.c_customer_id AND rs.sales_rank <= 5
GROUP BY 
    fs.customer_id, fs.total_sales, fs.total_orders, fs.customer_value
ORDER BY 
    fs.total_sales DESC;

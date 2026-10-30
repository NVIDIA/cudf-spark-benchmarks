WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn,
        cd.cd_gender,
        ca.ca_state,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546  
),
GroupedSales AS (
    SELECT 
        sd.ca_state,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(*) AS transaction_count,
        AVG(sd.total_net_paid) AS avg_net_paid
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1  
    GROUP BY 
        sd.ca_state
)
SELECT 
    g.ca_state,
    g.total_sales,
    g.transaction_count,
    g.avg_net_paid,
    CASE 
        WHEN g.total_sales > 10000 THEN 'High'
        WHEN g.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    GroupedSales g
ORDER BY 
    g.total_sales DESC
LIMIT 10;
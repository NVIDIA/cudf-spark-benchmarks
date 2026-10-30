
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
AggregatedSales AS (
    SELECT 
        sd.ca_state,
        sd.cd_gender,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_sales
    FROM 
        SalesData sd
    GROUP BY 
        sd.ca_state, sd.cd_gender
)
SELECT 
    asales.ca_state,
    asales.cd_gender,
    asales.total_quantity,
    asales.total_sales,
    RANK() OVER (PARTITION BY asales.ca_state ORDER BY asales.total_sales DESC) AS sales_rank
FROM 
    AggregatedSales asales
WHERE 
    asales.total_sales > 1000
ORDER BY 
    asales.ca_state, sales_rank;

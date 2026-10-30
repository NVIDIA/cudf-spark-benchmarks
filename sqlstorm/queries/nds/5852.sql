
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_price,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023
        AND ca.ca_state = 'CA'
    GROUP BY 
        ws.ws_item_sk, ws.ws_web_site_sk
),
ItemStats AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_price,
        sd.last_sale_date
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE 
        sd.total_quantity > 100
)
SELECT 
    COUNT(*) AS number_of_items,
    SUM(total_sales) AS total_revenue,
    AVG(avg_price) AS average_sales_price,
    MIN(last_sale_date) AS first_sale_date,
    MAX(last_sale_date) AS last_sale_date
FROM 
    ItemStats;

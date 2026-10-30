
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        d.d_year,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, ca.ca_city, cd.cd_gender, cd.cd_marital_status
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_sales,
    ts.total_net_paid,
    sd.ca_city,
    sd.cd_gender,
    sd.cd_marital_status,
    SUM(sd.total_sales) OVER (PARTITION BY sd.ca_city) AS city_total_sales,
    COUNT(*) OVER () AS total_items_in_year
FROM 
    TopSales ts
JOIN 
    SalesData sd ON ts.ws_item_sk = sd.ws_item_sk
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.total_sales DESC;


WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
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
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, ca.ca_state, cd.cd_gender, cd.cd_marital_status
),
AggregatedSales AS (
    SELECT 
        sd.ws_item_sk,
        AVG(sd.total_quantity) AS avg_quantity,
        AVG(sd.total_sales) AS avg_sales,
        AVG(sd.total_discount) AS avg_discount,
        sd.d_year,
        sd.d_month_seq,
        sd.ca_state,
        sd.cd_gender,
        sd.cd_marital_status
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_item_sk, sd.d_year, sd.d_month_seq, sd.ca_state, sd.cd_gender, sd.cd_marital_status
)
SELECT 
    ais.avg_quantity,
    ais.avg_sales,
    ais.avg_discount,
    ais.d_year,
    ais.d_month_seq,
    ais.ca_state,
    ais.cd_gender,
    ais.cd_marital_status
FROM 
    AggregatedSales ais
INNER JOIN 
    inventory inv ON ais.ws_item_sk = inv.inv_item_sk
WHERE 
    inv.inv_quantity_on_hand < 50
ORDER BY 
    ais.avg_sales DESC;

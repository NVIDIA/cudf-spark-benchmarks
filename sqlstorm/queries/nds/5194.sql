
WITH SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_sales_price - ws.ws_ext_discount_amt) AS total_net_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ws.ws_sold_date_sk
),
RankedSales AS (
    SELECT 
        sd.c_customer_sk,
        sd.c_first_name,
        sd.c_last_name,
        sd.ca_city,
        sd.total_quantity,
        sd.total_sales,
        sd.total_net_sales,
        RANK() OVER (PARTITION BY sd.ca_city ORDER BY sd.total_net_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    rs.ca_city,
    rs.total_quantity,
    rs.total_sales,
    rs.total_net_sales,
    rs.sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.ca_city, rs.sales_rank;

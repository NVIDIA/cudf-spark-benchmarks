
WITH SalesData AS (
    SELECT 
        web_sales.ws_item_sk,
        SUM(web_sales.ws_quantity) AS total_quantity,
        SUM(web_sales.ws_sales_price) AS total_sales,
        SUM(web_sales.ws_net_profit) AS total_profit,
        DATE_DIM.d_year,
        DATE_DIM.d_month_seq
    FROM 
        web_sales
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        web_sales.ws_item_sk, 
        DATE_DIM.d_year, 
        DATE_DIM.d_month_seq
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity,
    rs.total_sales,
    rs.total_profit,
    rs.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_state
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
JOIN 
    customer c ON i.i_item_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC, rs.total_profit DESC;

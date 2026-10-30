
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit,
        dd.d_year,
        cd.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ws_item_sk, dd.d_year, cd.cd_gender, ca.ca_state
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year, 
    cd_gender, 
    ca_state, 
    SUM(total_quantity) AS total_quantity_sold, 
    SUM(total_sales) AS total_revenue, 
    AVG(average_profit) AS avg_profit_per_item
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    d_year, cd_gender, ca_state
ORDER BY 
    d_year, cd_gender, total_revenue DESC;

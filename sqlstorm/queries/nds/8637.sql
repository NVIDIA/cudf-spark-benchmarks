
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        c.c_birth_year,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, 
        c.c_birth_year, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        ca.ca_state
), RankingData AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    ca_state,
    c_birth_year,
    cd_marital_status,
    cd_gender,
    total_quantity_sold,
    total_sales,
    total_discount,
    sales_rank
FROM 
    RankingData
WHERE 
    sales_rank <= 5
ORDER BY 
    ca_state, total_sales DESC;

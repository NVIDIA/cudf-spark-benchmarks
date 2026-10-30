
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        dd.d_year,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE 
        dd.d_year = 2022
        AND cd.cd_marital_status = 'M'
        AND ca.ca_state = 'CA'
    GROUP BY 
        ws.ws_sold_date_sk, dd.d_year
),
aggregated_data AS (
    SELECT 
        d_year,
        SUM(total_sales) AS yearly_sales,
        SUM(total_tax) AS yearly_tax,
        SUM(order_count) AS total_orders,
        SUM(unique_customers) AS total_customers
    FROM 
        sales_data
    GROUP BY 
        d_year
)
SELECT 
    ad.d_year,
    ad.yearly_sales,
    ad.yearly_tax,
    ad.total_orders,
    ad.total_customers,
    (ad.yearly_sales - ad.yearly_tax) AS net_sales
FROM 
    aggregated_data ad
ORDER BY 
    ad.d_year DESC;

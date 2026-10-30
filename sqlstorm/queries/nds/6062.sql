
WITH CustomerSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
),
ReturnsSummary AS (
    SELECT 
        dd.d_year,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    cs.ca_state,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.total_dependents,
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.avg_order_value,
    rs.total_returns,
    rs.total_returned_amount
FROM 
    CustomerSummary cs
JOIN 
    SalesSummary ss ON cs.total_customers > 1000 
JOIN 
    ReturnsSummary rs ON ss.d_year = rs.d_year
ORDER BY 
    cs.total_customers DESC, ss.total_sales DESC
LIMIT 10;

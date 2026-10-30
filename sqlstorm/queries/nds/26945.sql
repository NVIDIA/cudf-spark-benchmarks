WITH SellerInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
),
SalesSummary AS (
    SELECT 
        di.d_year,
        SUM(ws.ws_net_profit) AS yearly_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim di ON ws.ws_sold_date_sk = di.d_date_sk
    GROUP BY 
        di.d_year
)
SELECT 
    si.s_store_name,
    si.total_sales,
    si.total_revenue,
    cd.cd_gender,
    cd.customer_count,
    cd.avg_purchase_estimate,
    ss.yearly_net_profit,
    ss.total_quantity_sold
FROM 
    SellerInfo si
JOIN 
    CustomerDemographics cd ON si.total_sales > 100  
JOIN 
    SalesSummary ss ON ss.total_quantity_sold > 5000 
ORDER BY 
    si.total_revenue DESC, 
    cd.customer_count DESC;
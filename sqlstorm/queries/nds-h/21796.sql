WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        r.r_name IS NOT NULL AND 
        l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        r.r_name
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(distinct o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) FILTER (WHERE o.o_orderstatus = 'O') AS avg_open_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        ca.c_custkey,
        ca.c_name,
        ca.total_orders,
        ca.avg_open_order_price,
        ROW_NUMBER() OVER (ORDER BY ca.total_orders DESC) AS rn
    FROM 
        CustomerAnalysis ca
    WHERE 
        ca.total_orders > 5
)
SELECT 
    rs.region_name,
    tc.c_name,
    tc.total_orders,
    COALESCE(tc.avg_open_order_price, 0) AS avg_order_price,
    CASE 
        WHEN tc.total_orders < 10 THEN 'Low' 
        WHEN tc.total_orders BETWEEN 10 AND 20 THEN 'Medium' 
        ELSE 'High' 
    END AS order_priority_status
FROM 
    RegionalSales rs
FULL OUTER JOIN 
    TopCustomers tc ON rs.unique_customers = tc.c_custkey
WHERE 
    (rs.total_sales IS NOT NULL OR tc.total_orders IS NOT NULL)
ORDER BY 
    rs.total_sales DESC NULLS LAST, 
    tc.total_orders DESC NULLS FIRST
LIMIT 50;
WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'F' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)

SELECT 
    rs.s_name AS Supplier_Name,
    rs.total_revenue AS Total_Revenue,
    cc.c_name AS Customer_Name,
    cc.order_count AS Order_Count
FROM 
    RankedSuppliers rs
LEFT JOIN 
    CustomerOrderCount cc ON cc.order_count > 0
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    rs.total_revenue DESC, cc.order_count DESC;
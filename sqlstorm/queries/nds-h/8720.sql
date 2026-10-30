WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.TotalRevenue, 
        s.TotalOrders, 
        RANK() OVER (ORDER BY s.TotalRevenue DESC) AS RevenueRank
    FROM 
        SupplierOrderSummary s
)
SELECT 
    r.r_name AS Region,
    COUNT(DISTINCT rs.s_suppkey) AS SupplierCount,
    AVG(rs.TotalRevenue) AS AvgRevenue,
    SUM(rs.TotalOrders) AS TotalOrdersReceived
FROM 
    RankedSuppliers rs
JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 0
ORDER BY 
    AvgRevenue DESC;
WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_r.s_suppkey,
        s_r.s_name,
        s_r.TotalRevenue,
        RANK() OVER (ORDER BY s_r.TotalRevenue DESC) AS RevenueRank
    FROM 
        SupplierRevenue s_r
)
SELECT 
    n.n_name AS Nation,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(o.o_totalprice) AS AvgOrderValue,
    COALESCE(ts.s_name, 'No Supplier') AS TopSupplier
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey AND ts.RevenueRank = 1
WHERE 
    o.o_orderdate >= '1997-01-01'
    AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY 
    n.n_name, ts.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalOrders DESC, Nation ASC
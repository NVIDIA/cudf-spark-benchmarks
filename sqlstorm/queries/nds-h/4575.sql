
WITH RegionalStats AS (
    SELECT 
        r.r_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT s.s_suppkey) AS UniqueSuppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderValue,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS TotalLineItems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        od.OrderValue, 
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY od.OrderValue DESC) AS OrderRank
    FROM 
        OrderDetails od
    JOIN 
        orders o ON od.o_orderkey = o.o_orderkey
    WHERE 
        od.OrderValue > 1000
),
SupplierProfitability AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS SupplierCost,
        COUNT(DISTINCT p.p_partkey) AS SuppliedParts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name,
    COALESCE(rs.TotalSupplyCost, 0) AS TotalSupplyCost,
    COALESCE(rs.UniqueSuppliers, 0) AS UniqueSuppliers,
    COALESCE(hvo.OrderValue, 0) AS HighValueOrderValue,
    COALESCE(sp.SupplierCost, 0) AS SupplierTotalCost,
    COALESCE(sp.SuppliedParts, 0) AS PartsSupplied
FROM 
    RegionalStats rs
FULL OUTER JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
        ORDER BY o.o_orderdate DESC 
        LIMIT 1
    )
FULL OUTER JOIN 
    SupplierProfitability sp ON sp.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
JOIN 
    region r ON r.r_name = rs.r_name
ORDER BY 
    r.r_name;

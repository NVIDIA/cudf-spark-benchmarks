WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_linenumber) AS LineItemCount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey
), CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(COALESCE(od.TotalRevenue, 0)) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), RegionNationTotals AS (
    SELECT 
        r.r_name,
        SUM(co.TotalSpent) AS TotalSpent,
        COUNT(co.c_custkey) AS CustomerCount
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    JOIN 
        CustomerOrderStats co ON co.c_custkey = c.c_custkey
    GROUP BY 
        r.r_name
)

SELECT 
    r.r_name,
    r.CustomerCount,
    r.TotalSpent,
    COALESCE((SELECT AVG(cs.TotalSpent) FROM CustomerOrderStats cs WHERE cs.OrderCount > 5), 0) AS AvgHighSpender,
    COALESCE((SELECT MAX(ss.TotalSupplyCost) FROM SupplierStats ss WHERE ss.PartCount > 3), 0) AS MaxSupplierCost
FROM 
    RegionNationTotals r
ORDER BY 
    r.TotalSpent DESC
LIMIT 10;
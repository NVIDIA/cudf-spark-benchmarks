WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS NumberOfParts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        SUM(o.o_totalprice) AS TotalRegionSales
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
    ORDER BY 
        TotalRegionSales DESC
    LIMIT 5
)
SELECT 
    ss.s_name,
    ss.TotalSupplyCost,
    ss.NumberOfParts,
    tr.TotalRegionSales
FROM 
    SupplierStats ss
JOIN 
    partsupp ps ON ss.s_suppkey = ps.ps_suppkey
JOIN 
    TopRegions tr ON ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        JOIN lineitem l ON p.p_partkey = l.l_partkey 
        JOIN orders o ON l.l_orderkey = o.o_orderkey 
        WHERE o.o_orderstatus = 'O' 
        GROUP BY p.p_partkey 
        HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    )
ORDER BY 
    ss.TotalSupplyCost DESC, 
    tr.TotalRegionSales DESC;

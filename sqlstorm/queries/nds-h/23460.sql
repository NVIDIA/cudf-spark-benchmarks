
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
            WHERE c2.c_mktsegment = c.c_mktsegment
        )
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT 
                AVG(ps2.ps_supplycost * ps2.ps_availqty)
            FROM 
                partsupp ps2
        )
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    DISTINCT r.r_name,
    rc.c_name,
    MAX(ho.TotalSupplyCost) AS MaxPartCost,
    SUM(ro.Revenue) FILTER (WHERE ro.LineItemCount > 1) AS HighValueRevenues
FROM 
    RankedCustomers rc
JOIN 
    nation n ON rc.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueParts ho ON ho.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost IS NOT NULL 
        AND ps.ps_availqty > (
            SELECT AVG(ps2.ps_availqty) 
            FROM partsupp ps2 
            WHERE ps2.ps_partkey = ps.ps_partkey
        )
    )
LEFT JOIN 
    RecentOrders ro ON rc.c_custkey = ro.o_custkey
GROUP BY 
    r.r_name, rc.c_name
HAVING 
    MAX(ho.TotalSupplyCost) IS NOT NULL
    AND SUM(ro.Revenue) > 1000
ORDER BY 
    r.r_name, rc.c_name;

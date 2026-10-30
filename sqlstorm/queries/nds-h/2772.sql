WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O') 
        AND o.o_totalprice > 1000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
MaxPartSupply AS (
    SELECT 
        ps_partkey,
        MAX(avg_supplycost) AS max_cost
    FROM 
        SupplierParts
    GROUP BY 
        ps_partkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(lp.total_availqty) AS avg_available_parts,
    COUNT(DISTINCT r.r_regionkey) AS regions_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    (SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty
     FROM 
        partsupp ps
     JOIN 
        MaxPartSupply mps ON ps.ps_partkey = mps.ps_partkey
     WHERE 
        ps.ps_supplycost = mps.max_cost
     GROUP BY 
        ps.ps_partkey) lp ON l.l_partkey = lp.ps_partkey
LEFT JOIN 
    region r ON c.c_nationkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
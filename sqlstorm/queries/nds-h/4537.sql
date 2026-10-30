
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '6 months'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    n.n_name,
    cs.total_spent,
    cs.order_count,
    ss.total_cost,
    ss.part_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerAnalysis cs ON n.n_nationkey = cs.c_custkey 
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey = cs.order_count
WHERE 
    (cs.total_spent IS NOT NULL OR ss.total_cost IS NOT NULL)
AND 
    EXISTS (SELECT 1 FROM RankedOrders ro WHERE ro.o_orderkey = cs.order_count AND ro.order_rank = 1)
ORDER BY 
    cs.total_spent DESC,
    ss.total_cost ASC
LIMIT 5 OFFSET 10;

WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate <= '1997-10-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPartCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 100
)
SELECT 
    p.p_name,
    rs.s_name,
    os.total_revenue,
    spc.total_cost,
    tr.r_name,
    tr.customer_count
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O' AND o.o_orderdate > cast('1998-10-01' as date) - interval '30 days'
    )
JOIN 
    SupplierPartCost spc ON spc.ps_partkey = p.p_partkey
JOIN 
    TopRegions tr ON rs.s_nationkey = tr.r_regionkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
        WHERE p2.p_size = p.p_size
    )
AND 
    rs.rn <= 3 
ORDER BY 
    total_revenue DESC, customer_count ASC;
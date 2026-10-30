WITH  OrderCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderkey) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
),
SupplierRanked AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost) ASC) AS supplier_rank
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    s.s_name,
    cs.total_spent,
    cs.order_count,
    sr.total_available,
    sr.supplier_rank
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    SupplierRanked sr ON sr.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = sr.ps_suppkey
LEFT JOIN 
    CustomerSummary cs ON cs.c_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = 1
        )
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
WHERE 
    l.l_quantity > 0
    AND sr.supplier_rank = 1
    AND (s.s_acctbal IS NULL OR s.s_acctbal < 1000)
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
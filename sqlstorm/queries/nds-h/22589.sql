WITH  PriceSummary AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(CASE 
            WHEN l.l_discount < 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS adjusted_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, 
        p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
), 
NationData AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region, 
        SUM(s.s_acctbal) AS total_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, 
        n.n_name, 
        r.r_name
    HAVING 
        SUM(s.s_acctbal) IS NOT NULL
)
SELECT 
    ps.ps_partkey, 
    ps.ps_suppkey, 
    COALESCE(ps.ps_availqty, 0) AS available_quantity,
    ps.ps_supplycost,
    COALESCE(p.adjusted_price, 0) AS price_summary,
    nd.total_balance
FROM 
    partsupp ps
LEFT JOIN 
    PriceSummary p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    NationData nd ON ps.ps_suppkey = nd.n_nationkey
WHERE 
    (ps.ps_availqty IS NULL OR ps.ps_supplycost < 5000) 
    AND EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_custkey = ps.ps_suppkey 
        AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = 'BUILDERS')
    )
ORDER BY 
    price_summary DESC,
    total_balance ASC 
LIMIT 100;
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
SupplierRegion AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_name AS nation,
        s.s_suppkey,
        s.s_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        RankedSuppliers s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    sr.nation,
    sr.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    SupplierRegion sr ON sr.s_suppkey = l.l_suppkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY 
    p.p_name, sr.nation, sr.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT AVG(total_revenue)
        FROM (
            SELECT 
                SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue
            FROM 
                lineitem l2
            JOIN 
                orders o2 ON l2.l_orderkey = o2.o_orderkey
            WHERE 
                l2.l_shipdate >= '1997-01-01' AND l2.l_shipdate < '1997-12-31'
            GROUP BY 
                o2.o_orderkey
        ) AS order_totals
    )
ORDER BY 
    total_revenue DESC, p.p_name;
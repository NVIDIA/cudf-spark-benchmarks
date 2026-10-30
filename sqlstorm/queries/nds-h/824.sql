WITH  SupplierRank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    s.s_name,
    COALESCE(sp.rank, 0) AS supplier_rank,
    SUM(l.l_quantity) AS total_quantity,
    AVG(TOV.total_value) AS avg_order_value,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierRank sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    TotalOrderValue TOV ON l.l_orderkey = TOV.o_orderkey
WHERE 
    p.p_size > 10 
    AND (l.l_discount > 0.05 OR p.p_retailprice < 50)
GROUP BY 
    p.p_name, s.s_name, sp.rank, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_order_value DESC, supplier_rank ASC;
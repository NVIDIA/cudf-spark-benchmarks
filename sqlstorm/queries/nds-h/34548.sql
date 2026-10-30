WITH  RegionalSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        r.r_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA'
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        r.r_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name <> 'ASIA' AND 
        s.s_acctbal > 1000
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= '1997-01-01' 
        AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
)
SELECT 
    rp.s_name AS supplier_name,
    tp.p_name AS part_name,
    tp.total_revenue,
    ROW_NUMBER() OVER (PARTITION BY rp.s_name ORDER BY tp.total_revenue DESC) AS revenue_rank
FROM 
    RegionalSuppliers rp
JOIN 
    partsupp ps ON rp.s_suppkey = ps.ps_suppkey
JOIN 
    TopParts tp ON ps.ps_partkey = tp.p_partkey
WHERE 
    tp.total_revenue IS NOT NULL
ORDER BY 
    rp.s_name, tp.total_revenue DESC
LIMIT 10;
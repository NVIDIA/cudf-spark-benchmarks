WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.nation_name
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank <= 5
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
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1995-12-31'
    GROUP BY 
        l.l_partkey
),
PartRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
)
SELECT 
    fs.s_name,
    fs.nation_name,
    pr.p_name,
    pr.total_revenue
FROM 
    FilteredSuppliers fs
JOIN 
    partsupp ps ON fs.s_suppkey = ps.ps_suppkey
JOIN 
    PartRevenue pr ON ps.ps_partkey = pr.p_partkey
WHERE 
    pr.total_revenue > 0
ORDER BY 
    fs.nation_name, pr.total_revenue DESC;
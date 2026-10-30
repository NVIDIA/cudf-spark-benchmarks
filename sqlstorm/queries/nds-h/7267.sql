WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supplycost
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_supplycost) AS nation_total_supplycost
    FROM 
        nation n
    JOIN 
        SupplierSales ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region,
    ns.n_name,
    ns.nation_total_supplycost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationSales ns ON n.n_nationkey = ns.n_nationkey
ORDER BY 
    r.r_name, ns.nation_total_supplycost DESC;
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank_within_region
    FROM 
        supplier AS s
    JOIN 
        nation AS n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region AS r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_regionkey, r.r_name
), NotableSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.region_name,
        rs.part_count,
        rs.rank_within_region
    FROM 
        RankedSuppliers AS rs
    WHERE 
        rs.rank_within_region <= 3
)
SELECT 
    ns.s_name,
    ns.region_name,
    ns.part_count,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM orders AS o 
     JOIN lineitem AS l ON o.o_orderkey = l.l_orderkey 
     JOIN partsupp AS ps ON l.l_partkey = ps.ps_partkey 
     WHERE ps.ps_suppkey = ns.s_suppkey) AS total_orders
FROM 
    NotableSuppliers AS ns
ORDER BY 
    ns.region_name, ns.part_count DESC;

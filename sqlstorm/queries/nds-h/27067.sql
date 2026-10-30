WITH ranked_parts AS (
    SELECT 
        p_partkey, 
        p_name, 
        COUNT(DISTINCT ps_suppkey) AS supplier_count,
        SUM(ps_supplycost * ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY COUNT(DISTINCT ps_suppkey) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p_partkey, p_name, p_type
),
region_summary AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(o.o_totalprice) AS total_sales,
        AVG(c.c_acctbal) AS average_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    rp.p_name, 
    rp.total_cost, 
    rs.region_name,
    rs.total_sales,
    rs.nation_count,
    rp.part_rank
FROM 
    ranked_parts rp
JOIN 
    region_summary rs ON rs.nation_count > rp.supplier_count
WHERE 
    rp.part_rank <= 5
ORDER BY 
    rs.total_sales DESC, rp.total_cost ASC;

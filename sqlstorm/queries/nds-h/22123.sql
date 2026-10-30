
WITH regional_stats AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS num_customers,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
part_supplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        PERCENT_RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
        CASE 
            WHEN EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty IS NULL) 
            THEN 'Uncertain Availability'
            ELSE 'Available'
        END AS availability_status
    FROM 
        part p
)
SELECT 
    rs.nation_name,
    rs.total_acctbal,
    rs.num_customers,
    rs.avg_order_value,
    rp.p_name,
    rp.price_rank,
    rp.availability_status,
    ps.total_available,
    ps.max_cost,
    ps.supplier_names
FROM 
    regional_stats rs
JOIN 
    ranked_parts rp ON rs.nation_name LIKE '%' || rp.p_name || '%'
LEFT JOIN 
    part_supplier ps ON rp.p_partkey = ps.ps_partkey
WHERE 
    (rp.availability_status = 'Available' OR ps.total_available IS NOT NULL)
    AND (rs.num_customers > 0 AND rs.avg_order_value > (SELECT AVG(o.o_totalprice) FROM orders o WHERE o.o_orderstatus != 'C'))
ORDER BY 
    rs.total_acctbal DESC, rp.price_rank ASC
LIMIT 50;


WITH  supplier_rank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice BETWEEN 10.00 AND 100.00
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 100
), order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
), final_summary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_order_value,
        SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supplycost,
        CASE 
            WHEN COUNT(o.o_orderkey) > 0 THEN AVG(os.total_line_revenue) 
            ELSE NULL 
        END AS avg_revenue_per_order
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        order_summary os ON o.o_orderkey = os.o_orderkey
    LEFT JOIN 
        partsupp ps ON ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier_rank s WHERE s.rank = 1)
    GROUP BY 
        n.n_name
)
SELECT 
    f.n_name,
    f.customer_count,
    f.total_order_value,
    f.total_supplycost,
    COALESCE(f.avg_revenue_per_order, 0) AS avg_revenue_per_order,
    COUNT(DISTINCT h.p_partkey) AS high_value_parts_count
FROM 
    final_summary f
LEFT JOIN 
    high_value_parts h ON f.n_name LIKE '%' || h.p_name || '%'
WHERE 
    f.total_order_value IS NOT NULL 
    AND f.customer_count > 10
GROUP BY 
    f.n_name, f.customer_count, f.total_order_value, f.total_supplycost, f.avg_revenue_per_order
ORDER BY 
    f.total_order_value DESC, 
    f.customer_count ASC
LIMIT 100;

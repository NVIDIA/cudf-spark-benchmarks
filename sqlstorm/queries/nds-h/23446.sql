WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
qualified_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
customer_segments AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 0
),
region_summary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r 
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
),
final_selection AS (
    SELECT 
        qp.o_orderkey,
        COALESCE(rp.p_name, 'Unknown Part') AS part_name,
        COALESCE(ts.total_supply_cost, 0) AS supplier_cost,
        cs.order_count AS customer_order_count,
        rs.nation_count AS total_nations
    FROM 
        qualified_orders qp
    LEFT JOIN 
        ranked_parts rp ON qp.o_orderkey = rp.p_partkey
    FULL OUTER JOIN 
        top_suppliers ts ON ts.s_name = 'Market Leader'
    JOIN 
        customer_segments cs ON cs.c_custkey = qp.o_orderkey
    CROSS JOIN 
        region_summary rs
    WHERE 
        qp.total_revenue > (SELECT AVG(total_revenue) FROM qualified_orders)
      AND 
        (rp.price_rank IS NULL OR rp.price_rank < 5)
)
SELECT 
    f.o_orderkey, 
    f.part_name, 
    f.supplier_cost,
    f.customer_order_count,
    f.total_nations
FROM 
    final_selection f
WHERE 
    f.supplier_cost IS NOT NULL 
  AND 
    (f.total_nations > 5 OR f.customer_order_count > 10)
ORDER BY 
    f.customer_order_count DESC, f.supplier_cost ASC;
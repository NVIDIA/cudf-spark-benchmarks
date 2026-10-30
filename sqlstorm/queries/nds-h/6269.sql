WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
), top_orders AS (
    SELECT * 
    FROM ranked_orders 
    WHERE rank <= 10
), supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderkey IN (SELECT o_orderkey FROM top_orders)
    GROUP BY 
        s.s_suppkey, s.s_name
), nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(td.total_supply_cost) AS total_cost_by_nation
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        supplier_details td ON s.s_suppkey = td.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_cost_by_nation
FROM 
    region r
JOIN 
    nation_summary ns ON r.r_regionkey = ns.n_nationkey
ORDER BY 
    r.r_name, ns.n_name;
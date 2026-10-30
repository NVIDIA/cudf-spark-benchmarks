WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_stats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < cast('1998-10-01' as date)
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
    AVG(ss.total_cost) AS average_supplier_cost,
    MAX(os.total_spent) AS max_customer_spent,
    SUM(CASE WHEN ls.net_revenue IS NOT NULL THEN ls.net_revenue ELSE 0 END) AS total_revenue,
    RANK() OVER (ORDER BY AVG(ss.total_cost) DESC) AS avg_cost_rank
FROM 
    nation n
LEFT JOIN 
    supplier_stats ss ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_name LIKE '%Co%') 
LEFT JOIN 
    order_summary os ON os.c_name LIKE '%' || n.n_name || '%'
LEFT JOIN 
    lineitem_stats ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    n.n_regionkey IS NOT NULL
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
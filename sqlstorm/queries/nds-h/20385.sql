WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts,
        COUNT(p.p_partkey) AS total_parts
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        s.s_suppkey
),
customer_region AS (
    SELECT 
        c.c_custkey,
        r.r_name AS region
    FROM 
        customer c 
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
order_details AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS net_revenue,
        AVG(lo.l_quantity) AS avg_quantity
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    coalesce(r.region, 'Unknown') AS customer_region,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    MAX(ro.o_totalprice) AS max_order_value,
    AVG(ss.total_supply_cost) AS avg_supplier_cost,
    AVG(od.net_revenue) AS avg_revenue_per_order
FROM 
    ranked_orders ro
LEFT JOIN 
    customer_region r ON r.c_custkey = (
        SELECT 
            c.c_custkey
        FROM 
            customer c 
        WHERE 
            c.c_acctbal IS NOT NULL AND 
            c.c_acctbal = (SELECT MAX(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = 'BUILDING')
        LIMIT 1
    )
LEFT JOIN 
    supplier_stats ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
        ORDER BY 
            ps.ps_supplycost
        LIMIT 1
    )
LEFT JOIN 
    order_details od ON od.l_orderkey = ro.o_orderkey
WHERE 
    ro.order_rank <= 5 
GROUP BY 
    r.region
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > (SELECT COUNT(*) FROM orders) / 10
ORDER BY 
    max_order_value DESC;
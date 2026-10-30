
WITH region_nation AS (
    SELECT 
        r.r_regionkey,
        r.r_name AS region_name,
        n.n_nationkey,
        n.n_name AS nation_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_totalprice > 500
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    rn.region_name,
    rn.nation_name,
    sp.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.o_orderkey,
    ls.total_revenue,
    ls.lineitem_count
FROM 
    region_nation rn
JOIN 
    supplier_parts sp ON rn.n_nationkey = sp.s_suppkey
JOIN 
    customer_orders co ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rn.n_nationkey)
JOIN 
    lineitem_summary ls ON co.o_orderkey = ls.l_orderkey
WHERE 
    ls.total_revenue > 1000
ORDER BY 
    rn.region_name, 
    ls.total_revenue DESC
LIMIT 100;

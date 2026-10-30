WITH supplier_part_cost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
nation_region_summary AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    spc.s_name,
    spc.total_cost,
    cos.total_orders,
    cos.total_spent,
    lis.total_quantity,
    lis.total_revenue,
    nrs.nation_name,
    nrs.region_name,
    nrs.customer_count
FROM 
    supplier_part_cost spc
JOIN 
    customer_order_summary cos ON spc.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX') LIMIT 1)
JOIN 
    lineitem_summary lis ON lis.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F' ORDER BY o.o_orderdate DESC LIMIT 1)
JOIN 
    nation_region_summary nrs ON nrs.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c LIMIT 1))
ORDER BY 
    spc.total_cost DESC, cos.total_spent DESC, lis.total_revenue DESC;

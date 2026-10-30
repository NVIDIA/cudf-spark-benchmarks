WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), 
active_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), 
part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name,
    ac.c_name,
    ac.total_spent,
    poi.p_name,
    poi.total_available,
    poi.avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    part_supplier_info poi ON s.s_suppkey = poi.p_partkey
LEFT JOIN 
    active_customers ac ON s.s_suppkey = ac.c_custkey
WHERE 
    (ac.c_acctbal IS NOT NULL AND ac.total_spent > 5000)
    OR 
    (ac.c_acctbal IS NULL AND poi.avg_supply_cost < 50.00)
ORDER BY 
    r.r_name, ac.total_spent DESC, poi.total_available DESC;
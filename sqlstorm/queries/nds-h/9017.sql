WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
), top_orders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_acctbal
    FROM 
        ranked_orders r
    WHERE 
        r.rank <= 10
), part_supplier_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_name,
    o.c_acctbal,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    ps.total_avail_qty,
    ps.avg_supply_cost
FROM 
    top_orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN part_supplier_summary ps ON p.p_partkey = ps.ps_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
ORDER BY 
    o.o_orderdate DESC, o.o_orderkey;
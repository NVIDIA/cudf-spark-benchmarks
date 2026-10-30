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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), high_value_orders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.rank,
        r.c_name,
        r.o_totalprice
    FROM 
        ranked_orders r
    WHERE 
        r.rank <= 5
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.c_name,
    h.o_totalprice,
    sp.ps_partkey,
    sp.total_available
FROM 
    high_value_orders h
JOIN 
    lineitem l ON h.o_orderkey = l.l_orderkey
JOIN 
    supplier_parts sp ON l.l_partkey = sp.ps_partkey
WHERE 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
ORDER BY 
    h.o_orderdate, h.o_totalprice DESC;
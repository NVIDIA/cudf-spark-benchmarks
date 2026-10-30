WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
top_orders AS (
    SELECT 
        order_rank, 
        o_orderkey, 
        o_orderstatus, 
        o_totalprice, 
        o_orderdate, 
        o_orderpriority, 
        c_name, 
        nation_name 
    FROM 
        ranked_orders 
    WHERE 
        order_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    o.o_orderpriority,
    o.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_partkey) AS unique_parts,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    top_orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    o.o_orderkey, 
    o.o_orderstatus, 
    o.o_totalprice, 
    o.o_orderdate, 
    o.o_orderpriority, 
    o.c_name
ORDER BY 
    total_revenue DESC, 
    o.o_orderdate
LIMIT 100;
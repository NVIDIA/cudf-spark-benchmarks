WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
total_lineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
top_suppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_cost DESC
    LIMIT 5
)
SELECT 
    c.c_name,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o_orderdate,
    li.total_revenue,
    ts.total_cost
FROM 
    customer c
JOIN 
    ranked_orders o ON c.c_custkey = o.o_orderkey
JOIN 
    total_lineitems li ON li.l_orderkey = o.o_orderkey
CROSS JOIN 
    (SELECT SUM(total_cost) AS total_cost FROM top_suppliers) ts
WHERE 
    o.order_rank <= 10
ORDER BY 
    o.o_orderdate DESC, 
    o.o_totalprice DESC;
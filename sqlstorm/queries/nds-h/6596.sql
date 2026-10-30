WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_item_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.c_name,
        o.supplier_name,
        o.total_line_item_value
    FROM 
        RankedOrders o
    WHERE 
        o.line_item_rank = 1
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT t.o_orderkey) AS order_count,
    SUM(t.total_line_item_value) AS total_value,
    AVG(t.o_totalprice) AS avg_order_price
FROM 
    TopOrders t
JOIN 
    supplier s ON t.supplier_name = s.s_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_value DESC
LIMIT 10;
